
load("@rules_python//python:pip.bzl", "pip_import", "pip_repositories")

def py_deps():

    excludes = native.existing_rules().keys()
    if "databricks_pip_deps" not in excludes:
        pip_repositories()

        # pip_import(
        #   name = "databricks_cli_import_dev",
        #   requirements = "@databricks_cli_src//:dev-requirements.txt",
        # )

        pip_import(
            name = "databricks_pip_deps",
            requirements = "@rules_databricks//databricks:requirements.txt",
        )
