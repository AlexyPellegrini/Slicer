import dataclasses
import pathlib
from typing import Annotated
import unittest

import vtk
import slicer

from MRMLCorePython import (
    vtkMRMLNode,
    vtkMRMLModelNode,
    vtkMRMLScalarVolumeNode,
)
from slicer.parameterNodeWrapper import *


def newParameterNode():
    node = slicer.mrmlScene.AddNewNodeByClass("vtkMRMLScriptedModuleNode")
    return node


@dataclasses.dataclass
class CustomClass:
    x: int
    y: int
    z: int


@parameterNodeSerializer
class CustomClassSerializer(Serializer):
    @staticmethod
    def canSerialize(type_) -> bool:
        return type_ == CustomClass

    @staticmethod
    def create(type_):
        if CustomClassSerializer.canSerialize(type_):
            return ValidatedSerializer(CustomClassSerializer(), [NotNone(), IsInstance(CustomClass)])
        return None

    def default(self):
        return None

    def isIn(self, parameterNode, name: str) -> bool:
        return parameterNode.HasParameter(name)

    def write(self, parameterNode, name: str, value) -> None:
        parameterNode.SetParameter(name, f"{value.x},{value.y},{value.z}")

    def read(self, parameterNode, name: str):
        val = parameterNode.GetParameter(name)
        vals = val.split(',')
        return CustomClass(int(vals[0]), int(vals[1]), int(vals[2]))

    def remove(self, parameterNode, name: str) -> None:
        parameterNode.UnsetParameter(name)


@dataclasses.dataclass
class AnotherCustomClass:
    a: int
    b: int
    c: int


# the big difference between this and CustomClassSerializer, is that the
# default for this is not None
@parameterNodeSerializer
class AnotherCustomClassSerializer(Serializer):
    @staticmethod
    def canSerialize(type_) -> bool:
        return type_ == AnotherCustomClass

    @staticmethod
    def create(type_):
        if AnotherCustomClassSerializer.canSerialize(type_):
            return ValidatedSerializer(AnotherCustomClassSerializer(), [IsInstance(AnotherCustomClass)])
        return None

    def default(self):
        return AnotherCustomClass(0, 0, 0)

    def isIn(self, parameterNode, name: str) -> bool:
        return parameterNode.HasParameter(name)

    def write(self, parameterNode, name: str, value) -> None:
        parameterNode.SetParameter(name, f"{value.a},{value.b},{value.c}" if value is not None else "None")

    def read(self, parameterNode, name: str):
        val = parameterNode.GetParameter(name)
        if val == "None":
            return None
        else:
            vals = val.split(',')
            return AnotherCustomClass(int(vals[0]), int(vals[1]), int(vals[2]))

    def remove(self, parameterNode, name: str) -> None:
        parameterNode.UnsetParameter(name)


# not registering as a @parameterNodeSerializer because we are overriding
# the serialization of a built in type and we don't want anyone else to accidentally
# use this.
class CustomIntSerializer(Serializer):
    """
    Stores ints as their negative.
    Used to test being able to use a specific serializer.
    """
    @staticmethod
    def canSerialize(type_) -> bool:
        return type_ == int

    @staticmethod
    def create(type_):
        if CustomIntSerializer.canSerialize(type_):
            return ValidatedSerializer(CustomIntSerializer(), [NotNone(), IsInstance(int)])
        return None

    def default(self):
        return 0

    def isIn(self, parameterNode, name: str) -> bool:
        return parameterNode.HasParameter(name)

    def write(self, parameterNode, name: str, value) -> None:
        parameterNode.SetParameter(name, str(-value))

    def read(self, parameterNode, name: str):
        return -int(parameterNode.GetParameter(name))

    def remove(self, parameterNode, name: str) -> None:
        parameterNode.UnsetParameter(name)


class TypedParameterNodeTest(unittest.TestCase):
    def setUp(self):
        slicer.mrmlScene.Clear(0)

    def test_removes(self):
        # for each serializer, make sure that calling remove from it
        # erases all trace of it in the parameterNode
        numberSerializer = NumberSerializer(int)
        stringSerializer = StringSerializer()
        pathSerializer = PathSerializer(pathlib.Path)
        boolSerializer = BoolSerializer()
        listSerializer = ListSerializer(NumberSerializer(float))

        parameterNode = newParameterNode()

        numberSerializer.write(parameterNode, "number", 1)
        stringSerializer.write(parameterNode, "string", "1")
        pathSerializer.write(parameterNode, "path", pathlib.Path("."))
        boolSerializer.write(parameterNode, "bool", True)
        listSerializer.write(parameterNode, "list", [1])

        numberSerializer.remove(parameterNode, "number")
        stringSerializer.remove(parameterNode, "string")
        pathSerializer.remove(parameterNode, "path")
        boolSerializer.remove(parameterNode, "bool")
        listSerializer.remove(parameterNode, "list")

        self.assertFalse(parameterNode.GetParameterNames())

    def test_isCached(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            int_: int
            listInt: list[int]
            custom: Annotated[CustomClass, Default(CustomClass(0, 0, 0))]
            listCustom: list[CustomClass]

        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("int_"))
        self.assertTrue(param.isCached("listInt"))
        self.assertFalse(param.isCached("custom"))
        self.assertFalse(param.isCached("listCustom"))
        with self.assertRaises(ValueError):
            param.isCached("notExistentParameter")

    def test_custom_validator(self):
        class Is777Or778(Validator):
            @staticmethod
            def validate(value):
                if value != 777 and value != 778:
                    raise ValueError("Twas not 777 or 778")

        @parameterNodeWrapper
        class ParameterNodeType:
            i: Annotated[int, Is777Or778, Default(777)]

        param = ParameterNodeType(newParameterNode())

        with self.assertRaises(ValueError):
            param.i = -2
        param.i = 778

    def test_custom_serializer(self):
        @parameterNodeWrapper
        class CustomClassParameterNode:
            # serializer for custom type will be found because it was decorate with @parameterNodeSerializer
            custom: Annotated[CustomClass, Default(CustomClass(0, 0, 0))]

            # custom serializer for built in type
            customInt: Annotated[int, CustomIntSerializer()]

        param = CustomClassParameterNode(newParameterNode())
        self.assertEqual(param.custom.x, 0)
        self.assertEqual(param.custom.y, 0)
        self.assertEqual(param.custom.z, 0)

        self.assertEqual(param.customInt, 0)

        param.customInt = 4
        self.assertEqual(param.parameterNode.GetParameter("customInt"), "-4")
        self.assertEqual(param.customInt, 4)

    def test_custom_serializer2(self):
        @parameterNodeWrapper
        class AnotherCustomClassParameterNode:
            normalDefault: AnotherCustomClass
            noneDefault: Annotated[AnotherCustomClass, Default(None)]
            nonNoneDefault: Annotated[AnotherCustomClass, Default(AnotherCustomClass(1, 2, 3))]

        param = AnotherCustomClassParameterNode(newParameterNode())
        self.assertEqual(param.normalDefault, AnotherCustomClass(0, 0, 0))
        self.assertIsNone(param.noneDefault)
        self.assertEqual(param.nonNoneDefault, AnotherCustomClass(1, 2, 3))

    def test_primitives(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            int1: int
            float1: float
            bool1: bool
            string1: str
            int2: Annotated[int, Default(4)]
            float2: Annotated[float, Default(9.9)]
            bool2: Annotated[bool, Default(True)]
            string2: Annotated[str, Default("TypedParam")]

        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("int1"))
        self.assertTrue(param.isCached("int2"))
        self.assertTrue(param.isCached("float1"))
        self.assertTrue(param.isCached("float2"))
        self.assertTrue(param.isCached("bool1"))
        self.assertTrue(param.isCached("bool2"))
        self.assertTrue(param.isCached("string1"))
        self.assertTrue(param.isCached("string2"))

        self.assertEqual(param.int1, 0)
        self.assertEqual(param.int2, 4)
        self.assertAlmostEqual(param.float1, 0.0)
        self.assertAlmostEqual(param.float2, 9.9)
        self.assertFalse(param.bool1)
        self.assertTrue(param.bool2)
        self.assertEqual(param.string1, "")
        self.assertEqual(param.string2, "TypedParam")

        param.int1 = 7
        self.assertEqual(param.int1, 7)
        param.float2 = 4  # allow implicit conversion from int
        self.assertAlmostEqual(param.float2, 4.0)
        param.float2 = 7.5
        self.assertAlmostEqual(param.float2, 7.5)
        param.bool1 = True
        self.assertTrue(param.bool1)
        param.string1 = "Python"
        self.assertEqual(param.string1, "Python")

        with self.assertRaises(ValueError):
            param.int1 = None
        with self.assertRaises(ValueError):
            param.float1 = None
        with self.assertRaises(ValueError):
            param.bool1 = None
        with self.assertRaises(ValueError):
            param.string1 = None

        param2 = ParameterNodeType(param.parameterNode)

        self.assertEqual(param2.int1, 7)
        self.assertEqual(param2.int2, 4)
        self.assertAlmostEqual(param2.float1, 0.0)
        self.assertAlmostEqual(param2.float2, 7.5)
        self.assertTrue(param2.bool1)
        self.assertTrue(param2.bool2)
        self.assertEqual(param.string1, "Python")
        self.assertEqual(param2.string2, "TypedParam")

    def test_pathlib(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            path: pathlib.Path
            purePath: pathlib.PurePath
            purePosixPath: Annotated[pathlib.PurePosixPath, Default(pathlib.PurePosixPath("/root"))]
            pureWindowsPath: pathlib.PureWindowsPath

        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("path"))
        self.assertTrue(param.isCached("purePath"))
        self.assertTrue(param.isCached("purePosixPath"))
        self.assertTrue(param.isCached("pureWindowsPath"))

        self.assertEqual(param.path, pathlib.Path())
        self.assertEqual(param.purePath, pathlib.PurePath())
        self.assertEqual(param.purePosixPath, pathlib.PurePosixPath("/root"))
        self.assertEqual(param.pureWindowsPath, pathlib.PureWindowsPath())

        self.assertIsInstance(param.path, pathlib.Path)
        self.assertIsInstance(param.purePath, pathlib.PurePath)
        self.assertIsInstance(param.purePosixPath, pathlib.PurePosixPath)
        self.assertIsInstance(param.pureWindowsPath, pathlib.PureWindowsPath)

        param.path = pathlib.Path("relativePath/folder")
        param.purePath = pathlib.PurePath("relativePath/folder")
        param.purePosixPath = pathlib.PurePosixPath("relativePath/folder")
        param.pureWindowsPath = pathlib.PureWindowsPath("relativePath/folder")

        self.assertEqual(param.path, pathlib.Path("relativePath/folder"))
        self.assertEqual(param.purePath, pathlib.PurePath("relativePath/folder"))
        self.assertEqual(param.purePosixPath, pathlib.PurePosixPath("relativePath/folder"))
        self.assertEqual(param.pureWindowsPath, pathlib.PureWindowsPath("relativePath/folder"))

        # test that it saved and can be read elsewhere
        param2 = ParameterNodeType(param.parameterNode)

        self.assertEqual(param2.path, pathlib.Path("relativePath/folder"))
        self.assertEqual(param2.purePath, pathlib.PurePath("relativePath/folder"))
        self.assertEqual(param2.purePosixPath, pathlib.PurePosixPath("relativePath/folder"))
        self.assertEqual(param2.pureWindowsPath, pathlib.PureWindowsPath("relativePath/folder"))

    def test_multiple_instances_are_independent(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            single: str
            multi: list[int]

        param1 = ParameterNodeType(newParameterNode())
        param2 = ParameterNodeType(newParameterNode())

        param1.single = "hi"
        param1.multi = [1, 2, 3]
        param2.single = "hello"
        param2.multi = [4, 5, 6]

        self.assertEqual(param1.single, "hi")
        self.assertEqual(param1.multi, [1, 2, 3])
        self.assertEqual(param2.single, "hello")
        self.assertEqual(param2.multi, [4, 5, 6])

    def test_list_int(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            p: list[int]

        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("p"))

        p = param.p
        self.assertEqual(len(p), 0)

        p.append(4)
        p.append(1)
        p.append(7)
        self.assertEqual(param.p, [4, 1, 7])

        with self.assertRaises(ValueError):
            p.append("hi")
        self.assertEqual(param.p, [4, 1, 7])

        p.reverse()
        self.assertEqual(param.p, [7, 1, 4])

        p.sort()
        self.assertEqual(param.p, [1, 4, 7])

        self.assertEqual(4, p.pop(1))
        self.assertEqual(param.p, [1, 7])

        p.remove(7)
        self.assertEqual(param.p, [1])

        with self.assertRaises(ValueError):
            p.remove(44)  # not in the list
        self.assertEqual(param.p, [1])

        p += [3, 4, 5]
        self.assertEqual(param.p, [1, 3, 4, 5])

        p *= 2
        self.assertEqual(param.p, [1, 3, 4, 5, 1, 3, 4, 5])

        del p[2]
        self.assertEqual(param.p, [1, 3, 5, 1, 3, 4, 5])

        p.insert(4, 66)
        self.assertEqual(param.p, [1, 3, 5, 1, 66, 3, 4, 5])

        p.clear()
        self.assertEqual(param.p, [])

        p.extend([2, 3, 4])
        self.assertEqual(param.p, [2, 3, 4])

        p[0] = 7
        self.assertEqual(param.p, [7, 3, 4])

        self.assertEqual(param.p[0], 7)
        self.assertEqual(param.p[1], 3)
        self.assertEqual(param.p[2], 4)

        with self.assertRaises(NotImplementedError):
            _ = p + [4]
        with self.assertRaises(NotImplementedError):
            _ = [4] + p
        with self.assertRaises(NotImplementedError):
            _ = p * 2
        with self.assertRaises(NotImplementedError):
            _ = 2 * p

        p += [4, 5, 6]
        self.assertEqual(param.p, [7, 3, 4, 4, 5, 6])

        p *= 2
        self.assertEqual(param.p, [7, 3, 4, 4, 5, 6, 7, 3, 4, 4, 5, 6])

        # setting param.p will invalidate p
        param.p = [5, 1, 2]
        self.assertEqual(param.p, [5, 1, 2])

        # set from tuple
        param.p = (7, 3, 4)
        self.assertEqual(param.p, [7, 3, 4])

        param2 = ParameterNodeType(param.parameterNode)
        self.assertEqual(param2.p, [7, 3, 4])

        # allow explicit conversion to list, which breaks observation
        nonObserved = list(param.p)
        self.assertIsInstance(nonObserved, list)
        self.assertEqual(nonObserved, [7, 3, 4])

        nonObserved.append(1)
        self.assertEqual(nonObserved, [7, 3, 4, 1])
        self.assertEqual(param.p, [7, 3, 4])

    def test_list_custom(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            p: list[CustomClass]

        param = ParameterNodeType(newParameterNode())
        self.assertFalse(param.isCached("p"))

        p = param.p
        self.assertEqual(len(p), 0)

        param.p = [CustomClass(1, 2, 3), CustomClass(4, 5, 6)]
        self.assertEqual(param.p, [CustomClass(1, 2, 3), CustomClass(4, 5, 6)])

        # test that it saved and can be read elsewhere
        param2 = ParameterNodeType(param.parameterNode)
        self.assertEqual(len(param2.p), 2)
        self.assertEqual(param2.p, [CustomClass(1, 2, 3), CustomClass(4, 5, 6)])

    def test_list_of_annotated(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            choices: list[Annotated[str, Choice(["yes", "no", "maybe"])]]

        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("choices"))

        param.choices.append("yes")

        self.assertEqual(param.choices, ["yes"])
        with self.assertRaises(ValueError):
            param.choices.append("invalid")
        self.assertEqual(param.choices, ["yes"])
        with self.assertRaises(ValueError):
            param.choices += ["no", "invalid"]
        self.assertEqual(param.choices, ["yes"])

        param.choices.extend(["maybe", "no"])
        self.assertEqual(param.choices, ["yes", "maybe", "no"])

    def test_list_of_lists(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            p: list[list[int]]
        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("p"))

        pl = param.p

        pl.append([])
        pl[0] = [1, 2, 3]
        pl.append([4, 5, 6])
        pl[1].append(7)

        pl[1][2] = 0

        self.assertEqual(param.p, [[1, 2, 3], [4, 5, 0, 7]])

        del pl[0]
        self.assertEqual(param.p, [[4, 5, 0, 7]])

        pl.insert(0, [6, 7])
        self.assertEqual(param.p, [[6, 7], [4, 5, 0, 7]])

        pl.pop(0)
        self.assertEqual(param.p, [[4, 5, 0, 7]])

        param2 = ParameterNodeType(param.parameterNode)
        self.assertEqual(param2.p, [[4, 5, 0, 7]])

    def test_node(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            inputs: list[vtkMRMLModelNode]
            output: vtkMRMLModelNode

        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("inputs"))
        self.assertTrue(param.isCached("output"))

        inputs = [slicer.mrmlScene.AddNewNodeByClass('vtkMRMLModelNode') for _ in range(5)]
        param.inputs = inputs
        self.assertEqual(param.inputs, inputs)

        self.assertIsInstance(param.inputs[0], vtkMRMLModelNode)

        output = slicer.mrmlScene.AddNewNodeByClass('vtkMRMLModelNode')
        param.output = output
        self.assertEqual(param.output, output)

        # cannot set a model to a markup
        with self.assertRaises(ValueError):
            param.output = slicer.mrmlScene.AddNewNodeByClass('vtkMRMLScalarVolumeNode')

        param.output = None
        self.assertIsNone(param.output)

    def test_node_baseclass(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            node: vtkMRMLNode

        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("node"))

        param.node = slicer.mrmlScene.AddNewNodeByClass('vtkMRMLModelNode')
        self.assertIsInstance(param.node, vtkMRMLModelNode)
        param.node = slicer.mrmlScene.AddNewNodeByClass('vtkMRMLScalarVolumeNode')
        self.assertIsInstance(param.node, vtkMRMLScalarVolumeNode)

        with self.assertRaises(ValueError):
            param.node = 4

    def test_events(self):
        class _Callback:
            def __init__(self):
                self.called = 0

            def call(self, caller, event):
                self.called += 1
        callback = _Callback()

        @parameterNodeWrapper
        class ParameterNodeType:
            i: int
            s: list[str]
            n: vtkMRMLNode

        param = ParameterNodeType(newParameterNode())
        self.assertTrue(param.isCached("i"))
        self.assertTrue(param.isCached("s"))
        self.assertTrue(param.isCached("n"))

        tag = param.AddObserver(vtk.vtkCommand.ModifiedEvent, callback.call)

        param.i = 4
        self.assertEqual(1, callback.called)

        obs = param.s
        obs += ('string1', 'string2')
        self.assertEqual(2, callback.called)

        list(param.s).append('Should not cause an event')
        self.assertEqual(2, callback.called)

        param.s = ['a', 'b', 'c']
        self.assertEqual(3, callback.called)

        param.n = slicer.mrmlScene.AddNewNodeByClass('vtkMRMLModelNode')
        self.assertEqual(4, callback.called)

        param.n = None
        self.assertEqual(5, callback.called)

        param.RemoveObserver(tag)
        param.i = 7
        self.assertEqual(5, callback.called)

    def test_validators(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            min0: Annotated[int, Minimum(0)]
            max0: Annotated[int, Maximum(0)]
            within0_10: Annotated[float, WithinRange(0, 10)]
            choiceStr: Annotated[str, Choice(['a', 'b', 'c']), Default('a')]
            excludeStr: Annotated[str, Exclude(['a', 'b', 'c'])]

        param = ParameterNodeType(newParameterNode())

        param.min0 = 0
        param.min0 = 4
        with self.assertRaises(ValueError):
            param.min0 = -1
        self.assertEqual(param.min0, 4)

        param.max0 = 0
        param.max0 = -4
        with self.assertRaises(ValueError):
            param.max0 = 1
        self.assertEqual(param.max0, -4)

        param.within0_10 = 0
        param.within0_10 = 10
        param.within0_10 = 5
        with self.assertRaises(ValueError):
            param.within0_10 = 11
        with self.assertRaises(ValueError):
            param.within0_10 = -1
        self.assertEqual(param.within0_10, 5)

        param.choiceStr = 'a'
        param.choiceStr = 'b'
        param.choiceStr = 'c'
        with self.assertRaises(ValueError):
            param.choiceStr = 'd'

        param.excludeStr = 'd'
        param.excludeStr = ''
        param.excludeStr = 'e'
        with self.assertRaises(ValueError):
            param.excludeStr = 'a'
        with self.assertRaises(ValueError):
            param.excludeStr = 'b'
        with self.assertRaises(ValueError):
            param.excludeStr = 'c'

    def test_overlapping_members(self):
        @parameterNodeWrapper
        class ParameterNodeType1:
            x: int
            y: int

        @parameterNodeWrapper
        class ParameterNodeType2:
            x: Annotated[int, Default(6)]
            z: int

        parameterNode = newParameterNode()
        param1 = ParameterNodeType1(parameterNode, prefix="type1")
        param2 = ParameterNodeType2(parameterNode, prefix="type2")

        self.assertEqual(param1.x, 0)
        self.assertEqual(param1.y, 0)
        self.assertEqual(param2.x, 6)
        self.assertEqual(param2.z, 0)

        param1.x = 4
        param1.y = 3
        param2.x = 7
        param2.z = 8

        self.assertEqual(param1.x, 4)
        self.assertEqual(param1.y, 3)
        self.assertEqual(param2.x, 7)
        self.assertEqual(param2.z, 8)

    def test_parameter_node_reuse(self):
        @parameterNodeWrapper
        class ParameterNodeType:
            x: int
            y: list[int]

        parameterNode = newParameterNode()
        param1 = ParameterNodeType(parameterNode, prefix="use1")
        param2 = ParameterNodeType(parameterNode, prefix="use2")

        self.assertEqual(param1.x, 0)
        self.assertEqual(param1.y, [])
        self.assertEqual(param2.x, 0)
        self.assertEqual(param2.y, [])

        param1.x = 4
        param1.y = [3]
        param2.x = 7
        param2.y = [8, 99]

        self.assertEqual(param1.x, 4)
        self.assertEqual(param1.y, [3])
        self.assertEqual(param2.x, 7)
        self.assertEqual(param2.y, [8, 99])

    def timing_test_timeit_read_int(self):
        """
        Manual test function that prints some benchmark timings.
        Can be used to test the speed of different MakeTypedParameterNode
        implementations.
        """
        @parameterNodeWrapper
        class ParameterNodeType:
            i: int
            mi: list[int]
            f: float
            mf: list[float]

        param = ParameterNodeType(newParameterNode())
        param.mi = [7] * 100
        param.mf = [7.0] * 100

        def seti():
            param.i = 7

        def setf():
            param.f = 7.0

        def setmi():
            param.mi = [7] * 100

        def setmf():
            param.mf = [7.0] * 100

        import timeit
        print("get int              ", timeit.timeit(lambda: param.i, number=100_000))
        print("set int              ", timeit.timeit(seti, number=100_000))
        print("get float            ", timeit.timeit(lambda: param.f, number=100_000))
        print("set float            ", timeit.timeit(setf, number=100_000))
        print("get list of 100 int  ", timeit.timeit(lambda: param.mi, number=100_000))
        print("set list of 100 int  ", timeit.timeit(setmi, number=100_000))
        print("get list of 100 float", timeit.timeit(lambda: param.mf, number=100_000))
        print("set list of 100 float", timeit.timeit(setmf, number=100_000))

        # failure so it shows up with ctest --output-on-failure
        self.assertTrue(False)