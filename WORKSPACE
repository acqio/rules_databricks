workspace(name = "rules_databricks")

load("@rules_databricks//databricks:repositories.bzl", "repositories")
repositories()

load("@rules_databricks//databricks/py:py_deps.bzl", py_deps = "deps")
py_deps()

load("@rules_databricks//databricks/py:py_pip_deps.bzl", py_pip_deps = "deps")
py_pip_deps()
