load("@databricks_cli_import_dev//:requirements.bzl", dev = "pip_install")
load("@databricks_cli_import//:requirements.bzl", "pip_install")

def deps():

    dev()
    pip_install()
