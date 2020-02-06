workspace(name = "rules_databricks")

load("//repositories:repositories.bzl", "repositories")
repositories()

load("@rules_python//python:repositories.bzl", "py_repositories")
py_repositories()

load("@rules_python//python:pip.bzl", "pip_repositories", "pip_import")
pip_repositories()

pip_import(
    name = "databricks_cli_import_dev",
    requirements = "@databricks_cli_src//:dev-requirements.txt",
)

pip_import(
    name = "databricks_cli_import",
    requirements = "//repositories:requirements.txt",
)

load("@databricks_cli_import_dev//:requirements.bzl", "pip_install")
pip_install()

load("@databricks_cli_import//:requirements.bzl", "pip_install")
pip_install()
