project(vtkSlicerSegmentationsModuleLogic)

set(classes
  vtkSlicerSegmentationsModuleLogic
  vtkSlicerSegmentationGeometryLogic
  vtkImageGrowCutSegment
  FibHeap
  vtkSegmentEditorLogic
  )

vtk_module_add_module(VTK::SlicerSegmentationsModuleLogic
  EXPORT_MACRO_PREFIX VTK_SLICER_SEGMENTATIONS_LOGIC
  CLASSES ${classes}
)
