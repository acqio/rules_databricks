load("//databricks/private/rules:configure.bzl", _configure = "configure")
load("//databricks/private/rules:fs.bzl", _fs = "fs")
load("//databricks/private/rules:libraries.bzl", _libraries = "libraries")

databricks_configure = _configure
databricks_fs = _fs
databricks_libraries = _libraries
