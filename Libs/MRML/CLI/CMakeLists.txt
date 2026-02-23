vtk_module_find_package(
  PACKAGE SlicerExecutionModel
  COMPONENTS ModuleDescriptionParser
  PRIVATE_IF_SHARED
)

# ITK - Import ITK targets required by ModuleDescriptionParser
vtk_module_find_package(
  PACKAGE ITK
  COMPONENTS ${ModuleDescriptionParser_ITK_COMPONENTS}
)

set(configure_header_file vtkMRMLCLIConfigure.h)
configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/${configure_header_file}.in
  ${CMAKE_CURRENT_BINARY_DIR}/${configure_header_file}
)

slicercore_generate_module_wrapper(
  HEADER_NAME "vtkMRMLCLIModule.h"
  OUTPUT_VAR wrapper_header_file
)

set(classes vtkMRMLCommandLineModuleNode)

set(headers
  vtkMRMLCLIExport.h
  "${CMAKE_CURRENT_BINARY_DIR}/${configure_header_file}"
  "${wrapper_header_file}"
)

vtk_module_add_module(Slicer::MRMLCLI
  EXPORT_MACRO_PREFIX VTK_MRML_CLI
  CLASSES ${classes}
  HEADERS
)

vtk_module_link(Slicer::MRMLCLI PUBLIC ${ITK_LIBRARIES} PRIVATE ModuleDescriptionParser)
vtk_module_include(Slicer::MRMLCLI PRIVATE ${ModuleDescriptionParser_INCLUDE_DIRS})
