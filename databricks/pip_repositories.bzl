load("@databricks_pip_deps//:requirements.bzl", "pip_install")

def pip_deps():
    pip_install()

    native.register_toolchains("@rules_databricks//toolchain/databricks:default_linux_toolchain")

    native.register_toolchains("@rules_databricks//:py_toolchain")
