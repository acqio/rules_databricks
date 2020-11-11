load("//databricks/private/rules:configure/main.bzl", "configure_alias")
load(":py_repositories.bzl", "py_deps")

dbk_configure = configure_alias

def deps():
    py_deps()
