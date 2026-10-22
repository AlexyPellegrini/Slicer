
function(slicer_vtk_module_build)
  cmake_parse_arguments(PARSE_ARGV 0 arg
    ""
    "SOURCE_DIR"
    "MODULES"
  )

  if(NOT arg_SOURCE_DIR)
    set(arg_SOURCE_DIR "${CMAKE_SOURCE_DIR}")
  endif()

  if(NOT arg_MODULES)
    message(FATAL_ERROR "Missing or empty argument MODULES.")
  endif()

  # The modules are grouped by the location of their sources. Each group is
  # scanned, built and wrapped with its own call (see below):
  #   base     -> <SOURCE_DIR>/Base
  #   libs     -> <SOURCE_DIR>/Libs
  #   loadable -> <SOURCE_DIR>/Modules/Loadable

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

  # ---------------------------------------------------------------------------
  # Scan each group of modules.
  #
  # Groups are scanned from the most to the least dependent (loadable, libs,
  # base), as recommended by VTK ("Scanning multiple groups of modules"): a scan
  # reports the modules it needs but does not contain through REQUIRES_MODULES,
  # which the next scan receives through REQUEST_MODULES. Modules that a scan
  # could not find are forwarded through UNRECOGNIZED_MODULES.
  # ---------------------------------------------------------------------------

  # --- Libs modules
  vtk_module_find_modules(libs_module_files "${arg_SOURCE_DIR}/Libs")
  vtk_module_scan(
    MODULE_FILES          ${libs_module_files}
    PROVIDES_MODULES      libs_modules
    REQUIRES_MODULES      required_modules
    REQUEST_MODULES       ${arg_MODULES}
    ENABLE_TESTS          "${enable_tests}"
  )

  # --- Base modules
  vtk_module_find_modules(base_module_files "${arg_SOURCE_DIR}/Base")
  vtk_module_scan(
    MODULE_FILES          ${base_module_files}
    PROVIDES_MODULES      base_modules
    REQUIRES_MODULES      required_modules
    REQUEST_MODULES       ${arg_MODULES}
    ENABLE_TESTS          "${enable_tests}"
  )

  # --- Loadable modules
  vtk_module_find_modules(loadable_module_files
    "${arg_SOURCE_DIR}/Modules"
    "${arg_SOURCE_DIR}/Utilities/Templates"
  )
  vtk_module_scan(
    MODULE_FILES          ${loadable_module_files}
    PROVIDES_MODULES      loadable_modules
    REQUIRES_MODULES      required_modules
    REQUEST_MODULES       ${arg_MODULES}
    ENABLE_TESTS          "${enable_tests}"
  )

  # ---------------------------------------------------------------------------
  # Build and wrap each group. Following the VTK recommendation, the builds are
  # done in reverse order of the scans (base, libs, loadable) so that a group's
  # dependencies are already targets when the group is built.
  # ---------------------------------------------------------------------------

  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${Slicer_BIN_DIR}")
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${Slicer_LIB_DIR}")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${Slicer_LIB_DIR}")
  # --- Libs and base modules ---------------------------------------------------------
  vtk_module_build(
    MODULES               ${libs_modules} ${base_modules}
    PACKAGE               SlicerLibs
    INSTALL_HEADERS       "${arg_INSTALL_HEADERS}"
    HEADERS_DESTINATION   "${lib_install_dir}/include"
    CMAKE_DESTINATION     "${lib_install_dir}/lib/cmake/Slicer"
    LICENSE_DESTINATION   "${lib_install_dir}"
    HIERARCHY_DESTINATION "${lib_install_dir}/hierarchy"
  )

  if(Slicer_USE_PYTHONQT)
    vtk_module_wrap_python(
      MODULES              ${libs_modules} ${base_modules}
      MODULE_DESTINATION   "${Slicer_SITE_PACKAGES_DIR}"
      PYTHON_PACKAGE       "slicer"
      SOABI                ""
      BUILD_STATIC         OFF
      BUILD_PYI_FILES      ON
      INSTALL_HEADERS      "${arg_INSTALL_HEADERS}"
    )
  endif()

  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${Slicer_QTLOADABLEMODULES_BIN_DIR}")
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${Slicer_QTLOADABLEMODULES_LIB_DIR}")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${Slicer_QTLOADABLEMODULES_LIB_DIR}")
  # --- Loadable modules -----------------------------------------------------
  # Loadable modules and their Python wrappers are built into
  # qt-loadable-modules. The wrappers are top-level Python modules (no Python
  # package) so that the module factory can import them by name.
  vtk_module_build(
    MODULES               ${loadable_modules}
    PACKAGE               SlicerLoadable
    INSTALL_HEADERS       "${arg_INSTALL_HEADERS}"
    HEADERS_DESTINATION   "${base_install_dir}/include"
    CMAKE_DESTINATION     "${base_install_dir}/lib/cmake/Slicer"
    LICENSE_DESTINATION   "${base_install_dir}"
    HIERARCHY_DESTINATION "${base_install_dir}/hierarchy"
  )

  if(Slicer_USE_PYTHONQT)
    vtk_module_wrap_python(
      MODULES             ${loadable_modules}
      PYTHON_PACKAGE      "slicer"
      MODULE_DESTINATION  "${Slicer_QTLOADABLEMODULES_SITE_PACKAGES_DIR}"
      SOABI               ""
      BUILD_STATIC        OFF
      BUILD_PYI_FILES     OFF
      INSTALL_HEADERS     "${arg_INSTALL_HEADERS}"
    )
  endif()

  # There are 3 names for each module
  # - The library name on disk, e.g. MRMLCore.[so/dll/dylib], this used to be the real name of the target too.
  # - The new VTK-like module name, e.g. Slicer::MRMLCore
  # - The real target name, e.g. MRMLCore (VTK module system only keep the trailing name)
  # For Slicer::MRMLCore this works as the real target name is the expected one
  # But for Slicer::ModuleMRML, that used to be called vtkSlicerModuleNameMRML, now has:
  # "vtkSlicerModuleNameMRML.[so/dll/sylib]" as output name, but "ModuleMRML" as target name.
  # This logic will map the output library name to be an alias on the module.
  foreach(module IN LISTS libs_modules loadable_modules)
    vtk_module_set_properties("${module}" INTERFACE_vtk_module_name "${module}")
    vtk_module_get_property("${module}"
      PROPERTY INTERFACE_vtk_module_library_name
      VARIABLE lib_name
    )
    # Create the legacy target
    if(NOT TARGET "${lib_name}")
      _vtk_module_real_target(real_target "${module}")
      add_library("${lib_name}" ALIAS "${real_target}")
    endif()
    # Provide legacy CMake variables removed in the transition.
    _slicer_define_compatibility_variable_for_module("${module}" "${lib_name}")
  endforeach()
  
  # For each modules, creates a compatibility python module in the legacy location
  # Slicer basic scripts are still in bin/python/slicer
  # Libs and base:
  # - before: "<root>/lib/Slicer-X.Y/NamePython.[pyd|so|dylib]" (in build, they were in bin on Windows for some reasons)
  # - now: "<root>/lib/site-packages/slicer/Name.[pyd|so|dylib]"
  # Loadables:
  # - before: "<root>/lib/Slicer-X.Y/qt-loadable-modules/NamePython.[pyd|so|dylib]"
  # - after: "<root>/lib/Slicer-X.Y/qt-loadable-modules/site-packages/slicer/Name.[pyd|so|dylib]"
  if(Slicer_USE_PYTHONQT)
    foreach(module IN LISTS libs_modules)
      _slicer_add_compatibility_module("${module}" "${Slicer_SITE_PACKAGES_DIR}")
    endforeach()
    foreach(module IN LISTS loadable_modules)
      _slicer_add_compatibility_module("${module}" "${Slicer_QTLOADABLEMODULES_LIB_DIR}/site-packages")
    endforeach()
  endif()
endfunction()

function(_slicer_deprecated_variable_callback variable access value current_list_file stack)
  if(access STREQUAL READ_ACCESS)
    message(DEPRECATION "Variable \"${variable}\" is deprecated and should no longer be used.")
  elseif(access STREQUAL UNKNOWN_READ_ACCESS)
    message(SEND_ERROR "Variable \"${variable}\" has been removed and must no longer be used.")
  endif()
endfunction()

macro(_slicer_define_compatibility_variable name value)
  if(NOT "${value}" STREQUAL "")
    set("${name}" "${value}" PARENT_SCOPE)
  endif()
  variable_watch("${name}" _slicer_deprecated_variable_callback)
endmacro()

macro(_slicer_define_compatibility_variable_for_module module_name legacy_name)
  _slicer_define_compatibility_variable("${legacy_name}_SOURCE_DIR" "")
  _slicer_define_compatibility_variable("${legacy_name}_BINARY_DIR" "")
  _slicer_define_compatibility_variable("${legacy_name}_INCLUDE_DIRS" "$<TARGET_PROPERTY:${module_name},INTERFACE_INCLUDE_DIRECTORIES>")
endmacro()

function(_slicer_add_compatibility_module module stem)
  vtk_module_get_property("${module}"
    PROPERTY INTERFACE_vtk_module_library_name
    VARIABLE lib_name
  )
  file(WRITE "${CMAKE_BINARY_DIR}/${stem}/${lib_name}Python.py"
    "from slicer.${lib_name} import *"
  )
  install(
    FILES "${CMAKE_BINARY_DIR}/${stem}/${lib_name}Python.py"
    DESTINATION "${Slicer_INSTALL_ROOT}${stem}"
  )
endfunction()
