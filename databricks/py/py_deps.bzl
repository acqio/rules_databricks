load("@bazel_tools//tools/build_defs/repo:http.bzl","http_archive")
load("@rules_python//python:repositories.bzl", "py_repositories")
load("@rules_python//python:pip.bzl", "pip_repositories", "pip_import")

def deps():

    databricks_cli_version = "0.9.1"
    http_archive(
        name = "databricks_cli_src",
        build_file_content = """
filegroup(
name = "src",
srcs = glob(
    ["databricks_cli/**/*.py"]),
visibility = ["//visibility:public"],
)
""",
        sha256 = "6b7748da9595b818618ce3810647f900304219122114472e6653c4ffcd302537",
        strip_prefix = "databricks-cli-%s" % databricks_cli_version,
        urls = [
            "https://github.com/databricks/databricks-cli/archive/%s.tar.gz" % databricks_cli_version
        ],
    )

    py_repositories()
    pip_repositories()

    pip_import(
      name = "databricks_cli_import_dev",
      requirements = "@databricks_cli_src//:dev-requirements.txt",
    )

    pip_import(
        name = "databricks_cli_import",
        requirements = "@rules_databricks//databricks/py:requirements.txt",
    )
