list(requested_modules
  # Base modules
  VTK::SlicerBaseLogic
  # Libs modules
  VTK::RemoteIO
  VTK::ITK
  VTK::SegmentationCore
  VTK::Teem
  # MRML modules
  VTK::MRMLCore
  VTK::MRMLCLI
  VTK::MRMLLogic
  VTK::MRMLDisplayableManager
  # Loadable modules
  VTK::SlicerAnnotationsModuleMRML
  VTK::SlicerAnnotationsModuleLogic
  VTK::SlicerCamerasModuleLogic
  VTK::SlicerColorsModuleMRML
  VTK::SlicerColorsModuleLogic
  VTK::SlicerColorsModuleVTKWidgets
  VTK::SlicerColorsModuleMRMLDisplayableManager
  VTK::SlicerCropVolumeModuleMRML
  VTK::SlicerCropVolumeModuleLogic
  VTK::SlicerDataModuleLogic
  VTK::SlicerMarkupsModuleMRML
  VTK::SlicerMarkupsModuleLogic
  VTK::SlicerMarkupsModuleVTKWidgets
  VTK::SlicerMarkupsModuleMRMLDisplayableManager
  VTK::SlicerModelsModuleLogic
  VTK::SlicerPlotsModuleLogic
  VTK::SlicerReformatModuleLogic
  VTK::SlicerSceneViewsModuleLogic
  VTK::SlicerSegmentationsModuleMRML
  VTK::SlicerSegmentationsModuleLogic
  VTK::SlicerSegmentationsModuleMRMLDisplayableManager
  VTK::SlicerSequencesModuleMRML
  VTK::SlicerSequencesModuleLogic
  VTK::SlicerSubjectHierarchyModuleLogic
  VTK::SlicerTablesModuleLogic
  VTK::SlicerTerminologiesModuleLogic
  VTK::SlicerTextsModuleLogic
  VTK::SlicerTransformsModuleLogic
  VTK::SlicerTransformsModuleMRMLDisplayableManager
  VTK::SlicerUnitsModuleLogic
  VTK::SlicerViewControllersModuleLogic
  VTK::SlicerVolumeRenderingModuleMRML
  VTK::SlicerVolumeRenderingModuleLogic
  VTK::SlicerVolumeRenderingModuleMRMLDisplayableManager
  VTK::SlicerVolumesModuleLogic
)

# VTK uses complex values (ON, OFF, DEFAULT, WANT, DONT_WANT) for enabling tests, abstract this away
set(enable_tests OFF)
if(BUILD_TESTING)
  set(enable_tests ON)
endif()

# TODO: what are the values currently used by Slicer
set(base_install_dir "slicer")
set(lib_install_dir "slicer")
set(python_lib_install_dir ".")

# Variables defined here are used by VTK module system
include(GNUInstallDirs)

vtk_module_find_modules(module_files ${arg_SOURCE_DIR})

vtk_module_scan(
  MODULE_FILES     ${module_files}
  REQUEST_MODULES  ${requested_modules}
  PROVIDES_MODULES modules
  ENABLE_TESTS     "${enable_tests}"
)

# Build modules without installing headers as this is a runtime only package
vtk_module_build(
  MODULES               ${modules}
  INSTALL_HEADERS       "${install_headers}"
  HEADERS_DESTINATION   "${base_install_dir}/include"
  LICENSE_DESTINATION   "${base_install_dir}"
  HIERARCHY_DESTINATION "${base_install_dir}/hierarchy"
  RUNTIME_DESTINATION   "bin/$<CONFIG>"
  ARCHIVE_DESTINATION   "bin/$<CONFIG>"
  LIBRARY_DESTINATION   "bin/$<CONFIG>"
)

if(Slicer_USE_PYTHONQT)
  # Wrap modules without installing headers as this is a runtime only package
  vtk_module_wrap_python(
    MODULES             ${modules}
    PYTHON_PACKAGE      "slicer"
    SOABI               "${Python${VTK_PYTHON_VERSION}_SOABI}"
    BUILD_STATIC        OFF
    BUILD_PYI_FILES     ON
    INSTALL_HEADERS     "${install_headers}"
    RUNTIME_DESTINATION "bin/$<CONFIG>"
    LIBRARY_DESTINATION "bin/$<CONFIG>"
  )
endif()
