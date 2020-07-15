# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Rules to load all dependencies of rules_databricks."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("//toolchain/databricks:configure.bzl", databricks_toolchain_configure = "toolchain_configure")

def repositories():
    """Download dependencies of container rules."""
    excludes = native.existing_rules().keys()

    if "bazel_skylib" not in excludes:

        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://github.com/bazelbuild/bazel-skylib/archive/1.0.2.tar.gz"
            ],
            strip_prefix = "bazel-skylib-1.0.2",
            sha256 = "e5d90f0ec952883d56747b7604e2a15ee36e288bb556c3d0ed33e818a4d971f2",
        )

    if "rules_python" not in excludes:

        http_archive(
            name = "rules_python",
            urls = [
                "https://github.com/bazelbuild/rules_python/releases/download/0.0.1/rules_python-0.0.1.tar.gz"
            ],
            sha256 = "aa96a691d3a8177f3215b14b0edc9641787abaaa30363a080165d06ab65e1161",
        )

    if "com_github_ali5h_rules_pip" not in excludes:

        http_archive(
            name = "com_github_ali5h_rules_pip",
            urls = [
                "https://github.com/ali5h/rules_pip/archive/2.1.1.tar.gz"
            ],
            strip_prefix = "rules_pip-2.1.1",
            sha256 = "f4644c7fc13c70e8de005f8cac63c9b209203ebb8cc7ca6cb55c3a42b558e2a6",
        )

    if "jq" not in excludes:

        http_file(
            name = "jq",
            urls = [
                "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
            ],
            sha256 = "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44",
            executable = True,
        )

    if "databricks_src" not in excludes:
        http_archive(
            name = "databricks_src",
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
            urls = [
                "https://github.com/databricks/databricks-cli/archive/0.11.0.tar.gz"
            ],
            sha256 = "99c307e68561deca48c46b4d4ee66701883fe38d51dcd199fa46eed24e4ad12c",
            strip_prefix = "databricks-cli-0.11.0",
        )

    native.register_toolchains("@rules_databricks//toolchain/databricks:default_linux_toolchain")

    if "databricks_config" not in excludes:
        databricks_toolchain_configure(name = "databricks_config")
