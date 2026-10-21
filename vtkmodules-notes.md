Some variables such as <name>_SOURCE_DIR are used but no longer exists
Targets name has been changed from <name> to VTK::<name> or similar

vtk wrap python macro enforces a package name,
so we can no longer drop loadable modules in a specific directory,
as the package name will be prepended to the output directory.
For example, MRMLCore output location is "bin[/$<CONFIG>]",
the package name is "slicer",
so build modules are placed in "bin[/$<CONFIG>]/slicer"...

Try vtkAddon wrapping
