# load("@databricks_cli_import_dev//:requirements.bzl", dev = "pip_install")
load("@databricks_pip_deps//:requirements.bzl", "pip_install")

def pip_deps():

    # dev()
    pip_install()
