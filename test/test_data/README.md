# Test Data

This folder data that can be used for the project tests.
Here is some info about the files:

- `go_proj` - is a directory.  It contains a simple go project that has
  dependencies and can build a few executables. Other test files are derived
  from this project. When updating the project, please make sure to update
  derived files accordingly using the `update-test-data` target in the Makefile.

- `go-proj-src.tgz` - is the packaged source of `go_proj` using the `archive
  go-proj` command.  As of this writing, other than some sanity checks in the
  test suite, there is no explicit requirement for this file to be related
  to the `go_proj` directory, however, to avoid confusion, it is a good idea
  to keep them in sync.
