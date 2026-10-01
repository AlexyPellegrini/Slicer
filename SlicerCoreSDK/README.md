# Slicer Core SDK

SlicerCore is an alternative build-system for the 3DSlicer project.  
It is intended to build a Python Package (wheel) from the core libraries and loadables modules of 3DSlicer.

This is a "SDK" to build extensions for Slicer Core in C++.

## About Slicer

Slicer, or 3D Slicer, is a free, open source software package for visualization and image analysis.

3D Slicer is natively designed to be available on multiple platforms, including Windows, Linux and macOS.

For 3DSlicer community announcements and support, visit:

    https://discourse.slicer.org

For documentation, tutorials, and more information, please see:

    https://www.slicer.org

For 3DSlicer source code, please see:

    https://github.com/Slicer/Slicer


## About Slicer Core

Slicer Core in a single sentence:
***Slicer Core is the Python package consisting of all 3DSlicer modules that do not depend on Qt.***

Slicer Core contains the following libraries of 3DSlicer:
- `Base/Logic`
- `Libs/*`
- `Modules/Loadables/[MRML|MRMLDM|Logic|VTKWidgets]`

This enables using 3DSlicer powerful MRML nodes system and associated medical-oriented algorithms in pure Python.

## Using Slicer Core SDK

slicer-core-sdk package contains a CMake install tree that can be consumed using scikit-build-core.

This enables extending Slicer Core from other packages.
For more information, please take a look at
[Slicer Core "build module" test](https://github.com/KitwareMedical/SlicerCore/tree/main/patch/SlicerCore/tests/packages/build_module).

## Acknowledgments

This project uses [3D Slicer](https://www.slicer.org/) source code, an open-source software platform for medical image informatics, image processing, and three-dimensional visualization:  
Fedorov A., Beichel R., Kalpathy-Cramer J., Finet J., Fillion-Robin J-C., Pujol S., Bauer C., Jennings D., Fennessy F.M., Sonka M., Buatti J., Aylward S.R., Miller J.V., Pieper S., Kikinis R. [3D Slicer as an Image Computing Platform for the Quantitative Imaging Network](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3466397/pdf/nihms383480.pdf). Magnetic Resonance Imaging. 2012 Nov;30(9):1323-41. PMID: 22770690. PMCID: PMC3466397.

## License

Apache License, Version 2.0.
See LICENSE file for details.
