load("//databricks/private/rules:configure/main.bzl", "configure_alias")
load("@rules_python//python:pip.bzl", "pip_install")

dbk_configure = configure_alias

def deps():
    pip_install(
        name = "databricks_pip_deps",
        requirements = "@rules_databricks//databricks:requirements.txt",
    )
