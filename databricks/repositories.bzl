load("//databricks/toolchain:configure.bzl", databricks_toolchain_configure = "toolchain_configure")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

def repositories():
    """Download dependencies of container rules."""

    http_archive(
        name = "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/archive/1.0.2.tar.gz",
        ],
        sha256 = "e5d90f0ec952883d56747b7604e2a15ee36e288bb556c3d0ed33e818a4d971f2",
        strip_prefix = "bazel-skylib-1.0.2",
    )

    http_archive(
        name = "rules_python",
        urls = [
            "https://github.com/bazelbuild/rules_python/releases/download/0.1.0/rules_python-0.1.0.tar.gz",
        ],
        sha256 = "b6d46438523a3ec0f3cead544190ee13223a52f6a6765a29eae7b7cc24cc83a0",
    )

    http_file(
        name = "jq",
        urls = [
            "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64",
        ],
        sha256 = "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44",
        executable = True,
    )

    http_archive(
        name = "databricks_src",
        urls = [
            "https://github.com/databricks/databricks-cli/archive/0.14.0.tar.gz",
        ],
        sha256 = "956ee06b00a837d030983d670042e604ec69a95942f0e7eb294e4b36c48f2fda",
        strip_prefix = "databricks-cli-0.14.0",
        build_file_content = """
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "src",
    srcs = glob(
        ["databricks_cli/**/*.py"],
    ),
    visibility = ["//visibility:public"],
)
""",
    )

    databricks_toolchain_configure(name = "databricks_config")
