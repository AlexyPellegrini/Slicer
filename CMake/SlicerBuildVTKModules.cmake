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
    Slicer::AnnotationsModuleLogic
    Slicer::AnnotationsModuleMRML
    Slicer::CamerasModuleLogic
    Slicer::ColorsModuleLogic
    Slicer::ColorsModuleMRML
    Slicer::ColorsModuleMRMLDisplayableManager
    Slicer::ColorsModuleVTKWidgets
    Slicer::CropVolumeModuleLogic
    Slicer::CropVolumeModuleMRML
    Slicer::DataModuleLogic
    Slicer::DICOMLibModuleLogic
    Slicer::GeneralizedReformatModuleLogic
    Slicer::GeneralizedReformatModuleMRML
    Slicer::MarkupsModuleLogic
    Slicer::MarkupsModuleMRML
    Slicer::MarkupsModuleMRMLDisplayableManager
    Slicer::MarkupsModuleVTKWidgets
    Slicer::ModelsModuleLogic
    Slicer::MultiVolumeExplorerModuleLogic
    Slicer::MultiVolumeExplorerModuleMRML
    Slicer::PlotsModuleLogic
    Slicer::ReformatModuleLogic
    Slicer::SceneViewsModuleLogic
    Slicer::SegmentationsModuleLogic
    Slicer::SegmentationsModuleMRML
    Slicer::SegmentationsModuleMRMLDisplayableManager
    Slicer::SequencesModuleLogic
    Slicer::SequencesModuleMRML
    Slicer::SubjectHierarchyModuleLogic
    Slicer::TablesModuleLogic
    Slicer::TerminologiesModuleLogic
    Slicer::TextsModuleLogic
    Slicer::TransformsModuleLogic
    Slicer::TransformsModuleMRMLDisplayableManager
    Slicer::UnitsModuleLogic
    Slicer::ViewControllersModuleLogic
    Slicer::VolumeRenderingModuleLogic
    Slicer::VolumeRenderingModuleMRML
    Slicer::VolumeRenderingModuleMRMLDisplayableManager
    Slicer::VolumesModuleLogic
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
  
  # There are 3 names for each module
  # - The library name on disk, e.g. MRMLCore.[so/dll/dylib], this used to be the real name of the target too.
  # - The new VTK-like module name, e.g. Slicer::MRMLCore
  # - The real target name, e.g. MRMLCore (VTK module system only keep the trailing name)
  # For Slicer::MRMLCore this works as the real target name is the expected one
  # But for Slicer::ModuleMRML, that used to be called vtkSlicerModuleName now has:
  # "vtkSlicerModuleName.[so/dll/sylib]" as output name, but "ModuleMRML" as target name.
  # This logic will map the output library name to be an alias on the module.
  foreach(module IN LISTS modules)
    vtk_module_set_properties("${module}" INTERFACE_vtk_module_name "${module}")
    vtk_module_get_property("${module}"
      PROPERTY INTERFACE_vtk_module_library_name
      VARIABLE lib_name
    )
    if(NOT TARGET "${lib_name}")
      message(STATUS "Creating alias ${lib_name} for ${module}.")
      _vtk_module_real_target(real_target "${module}")
      add_library("${lib_name}" ALIAS "${real_target}")
    endif()
  endforeach()
endfunction()
