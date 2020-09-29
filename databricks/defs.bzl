load("//databricks/private/rules:configure/main.bzl", _configure = "configure")
load("//databricks/private/rules:fs/main.bzl", _fs = "fs")
load("//databricks/private/rules:libraries/main.bzl", _libraries = "libraries")

dbk_configure = _configure
dbk_fs = _fs
dbk_libraries = _libraries
