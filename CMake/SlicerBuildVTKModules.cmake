function(slicer_build_vtk_modules)
  cmake_parse_arguments(PARSE_ARGV 0 arg
    ""
    "SOURCE_DIR;INSTALL_HEADERS"
    "")

  if(NOT arg_SOURCE_DIR)
    message(FATAL_ERROR "slicer_build_vtk_modules requires SOURCE_DIR.")
  endif()

  set(requested_modules
    # Base modules
    Slicer::BaseLogic
    # Libs modules
    Slicer::RemoteIO
    Slicer::ITK
    Slicer::SegmentationCore
    Slicer::Teem
    # MRML modules
    Slicer::MRMLCore
    Slicer::MRMLCLI
    Slicer::MRMLLogic
    Slicer::MRMLDisplayableManager
    # Loadable modules
    Slicer::AnnotationsModuleMRML
    Slicer::AnnotationsModuleLogic
    Slicer::CamerasModuleLogic
    Slicer::ColorsModuleMRML
    Slicer::ColorsModuleLogic
    Slicer::ColorsModuleVTKWidgets
    Slicer::ColorsModuleMRMLDisplayableManager
    Slicer::CropVolumeModuleMRML
    Slicer::CropVolumeModuleLogic
    Slicer::DataModuleLogic
    Slicer::MarkupsModuleMRML
    Slicer::MarkupsModuleLogic
    Slicer::MarkupsModuleVTKWidgets
    Slicer::MarkupsModuleMRMLDisplayableManager
    Slicer::ModelsModuleLogic
    Slicer::PlotsModuleLogic
    Slicer::ReformatModuleLogic
    Slicer::SceneViewsModuleLogic
    Slicer::SegmentationsModuleMRML
    Slicer::SegmentationsModuleLogic
    Slicer::SegmentationsModuleMRMLDisplayableManager
    Slicer::SequencesModuleMRML
    Slicer::SequencesModuleLogic
    Slicer::SubjectHierarchyModuleLogic
    Slicer::TablesModuleLogic
    Slicer::TerminologiesModuleLogic
    Slicer::TextsModuleLogic
    Slicer::TransformsModuleLogic
    Slicer::TransformsModuleMRMLDisplayableManager
    Slicer::UnitsModuleLogic
    Slicer::ViewControllersModuleLogic
    Slicer::VolumeRenderingModuleMRML
    Slicer::VolumeRenderingModuleLogic
    Slicer::VolumeRenderingModuleMRMLDisplayableManager
    Slicer::VolumesModuleLogic
    Slicer::GeneralizedReformatModuleMRML
    Slicer::GeneralizedReformatModuleLogic
    Slicer::MultiVolumeExplorerModuleMRML
    Slicer::MultiVolumeExplorerModuleLogic
    Slicer::DICOMLibModuleLogic
    # LoadableCustomMarkups template
    Slicer::TemplateKeyModuleMRML
    Slicer::TemplateKeyModuleVTKWidgets
    Slicer::TemplateKeyModuleLogic
  )

  # VTK uses complex values (ON, OFF, DEFAULT, WANT, DONT_WANT) for enabling tests, abstract this away
  # Module tests are not built during the transition to VTK modules: the legacy Slicer test
  # infrastructure is not compatible with the VTK module build.
  set(enable_tests OFF)

  # TODO: what are the values currently used by Slicer
  set(base_install_dir "slicer")
  set(lib_install_dir "slicer")
  set(python_lib_install_dir ".")

  if(NOT DEFINED arg_INSTALL_HEADERS)
    set(arg_INSTALL_HEADERS OFF)
  endif()

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
    INSTALL_HEADERS       "${arg_INSTALL_HEADERS}"
    HEADERS_DESTINATION   "${base_install_dir}/include"
    CMAKE_DESTINATION     "${base_install_dir}/lib/cmake/Slicer"
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
      INSTALL_HEADERS     "${arg_INSTALL_HEADERS}"
      LIBRARY_DESTINATION "bin"
    )
  endif()

  # Provide legacy Slicer target names and CMake variables that referenced
  # libraries now built as VTK modules.
  include(SlicerVTKModuleCompat)
endfunction()
