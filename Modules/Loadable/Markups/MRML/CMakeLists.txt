find_package(RapidJSON REQUIRED)

set(classes
  vtkMRMLMarkupsJsonElement
  vtkMRMLMarkupsJsonStorageNode
  vtkMRMLMarkupsPlaneJsonStorageNode
  vtkMRMLMarkupsROIJsonStorageNode
  )

vtk_module_add_module(VTK::SlicerMarkupsModuleMRML
  EXPORT_MACRO_PREFIX VTK_SLICER_MARKUPS_MODULE_MRML
  CLASSES ${classes}
)

vtk_module_link(VTK::SlicerMarkupsModuleMRML PUBLIC RapidJSON)
