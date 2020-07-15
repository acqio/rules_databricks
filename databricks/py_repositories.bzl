load("@com_github_ali5h_rules_pip//:defs.bzl", "pip_import")

def py_deps():

    excludes = native.existing_rules().keys()
    if "databricks_pip_deps" not in excludes:

        pip_import(
            name = "databricks_pip_deps",
            python_interpreter = "python2",
            requirements = "@rules_databricks//databricks:requirements.txt",
        )
