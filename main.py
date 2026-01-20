from vtkmodules.vtkCommonMath import vtkMatrix4x4
from slicer import vtkMRMLLinearTransformNode, vtkMRMLTransformStorageNode

def test_is_compatible_with_transform_h5_export():
    # create transform node
    node = vtkMRMLLinearTransformNode()
    m44 = vtkMatrix4x4()
    m44.Identity()
    node.SetMatrixTransformToParent(m44)

    storage_node = vtkMRMLTransformStorageNode()
    storage_node.SetFileName("transform.h5")
    storage_node.SetUseCompression(True)

    node.SetAndObserveStorageNodeID(storage_node.GetID())
    storage_node.WriteData(node)
    
if __name__ == "__main__":
    test_is_compatible_with_transform_h5_export()
