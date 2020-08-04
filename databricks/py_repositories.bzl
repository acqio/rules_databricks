load("@rules_python//python:pip.bzl", "pip_import", "pip_repositories")

def py_deps():
    pip_repositories()

    pip_import(
        name = "databricks_pip_deps",
        requirements = "@rules_databricks//databricks:requirements.txt",
    )
