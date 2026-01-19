# /bin/bash

# install missing audit dependencies
pip install auditwheel patchelf

lib_paths="${PWD}/wheelbuild/ITK-build/bin:${PWD}/wheelbuild/ITK-build/lib:${PWD}/wheelbuild/VMTK-build/vtkVmtk/bin:${PWD}/wheelbuild/LibArchive-build/libarchive:${PWD}/wheelbuild/SlicerExecutionModel-build/ModuleDescriptionParser/bin:${PWD}/wheelbuild/vtkAddon-build:${PWD}/wheelbuild/JsonCpp-build/lib:${PWD}/wheelbuild/SurfaceToolbox-build/lib"
export LD_LIBRARY_PATH=${lib_paths}

auditwheel repair \
    --exclude="libvtkAccelerators*" --exclude="libvtkcgns*" --exclude="libvtkCharts*" --exclude="libvtkCommon*" \
    --exclude="libvtkDICOM*" --exclude="libvtkDomains*" --exclude="libvtkdoubleconversion*" --exclude="libvtkexodusII*" \
    --exclude="libvtkexpat*" --exclude="libvtkFilters*" --exclude="libvtkfmt*" --exclude="libvtkfreetype*" \
    --exclude="libvtkGeovis*" --exclude="libvtkgl2ps*" --exclude="libvtkglad*" --exclude="libvtkh5part*" \
    --exclude="libvtkhdf5*" --exclude="libvtkImaging*" --exclude="libvtkInfovis*" --exclude="libvtkInteraction*" \
    --exclude="libvtkIO*" --exclude="libvtkioss*" --exclude="libvtkjpeg*" --exclude="libvtkjsoncpp*" \
    --exclude="libvtkkissfft*" --exclude="libvtklibharu*" --exclude="libvtklibproj*" --exclude="libvtklibxml2*" \
    --exclude="libvtkloguru*" --exclude="libvtklz4*" --exclude="libvtklzma*" --exclude="libvtkm*" \
    --exclude="libvtkmetaio*" --exclude="libvtknetcdf*" --exclude="libvtkogg*" --exclude="libvtkParallel*" \
    --exclude="libvtkpng*" --exclude="libvtkpugixml*"  --exclude="libvtkPythonContext2D*" --exclude="libvtkRendering*" \
    --exclude="libvtkSerializationManager*" --exclude="libvtksqlite*" --exclude="libvtksys*" --exclude="libvtkTesting*" \
    --exclude="libvtktheora*" --exclude="libvtktiff*" --exclude="libvtktoken*" --exclude="libvtkUtilities*" \
    --exclude="libvtkverdict*" --exclude="libvtkViews*" --exclude="libvtkvpic*" --exclude="libvtkWeb*" \
    --exclude="libvtkWrapping*" --exclude="libvtkxdmf2*" --exclude="libvtkzfp*" --exclude="libvtkzlib*" \
    --exclude="libvtkscn*" --exclude="libviskores*" \
    --plat manylinux_2_35_x86_64 \
    vtk_mrml-9.5.0-cp310-cp310-linux_x86_64.whl \
    2>&1 | grep -v "INFO:"