workspace(name = "rules_databricks")

load("@rules_databricks//databricks:repositories.bzl", databricks_repositories = "repositories")

databricks_repositories()

load("@rules_databricks//databricks:deps.bzl", databricks_deps = "deps")

databricks_deps()

load("@rules_databricks//databricks:pip_repositories.bzl", databricks_pip_deps = "pip_deps")

databricks_pip_deps()

register_toolchains("@rules_databricks//databricks/toolchain:default_linux_toolchain")
