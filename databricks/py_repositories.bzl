load("@rules_python//python:pip.bzl", "pip_install")

def py_deps():
    pip_install(
        name = "databricks_pip_deps",
        requirements = "@rules_databricks//databricks:requirements.txt",
    )
