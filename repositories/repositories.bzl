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

load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive", "http_file"
)

load(
    "@rules_databricks//toolchains/databricks:toolchain.bzl", "toolchain_configure",
)

def repositories():
    """Download dependencies of container rules."""
    excludes = native.existing_rules().keys()

    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            sha256 = "e5d90f0ec952883d56747b7604e2a15ee36e288bb556c3d0ed33e818a4d971f2",
            strip_prefix = "bazel-skylib-1.0.2",
            urls = ["https://github.com/bazelbuild/bazel-skylib/archive/1.0.2.tar.gz"],
        )

        http_archive(
            name = "rules_python",
            url = "https://github.com/bazelbuild/rules_python/releases/download/0.0.1/rules_python-0.0.1.tar.gz",
            sha256 = "aa96a691d3a8177f3215b14b0edc9641787abaaa30363a080165d06ab65e1161",
        )

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

        jq_version = "1.6"
        http_file(
            name = "jq",
            executable = True,
            sha256 = "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44",
            urls = [
                "https://github.com/stedolan/jq/releases/download/jq-%s/jq-linux64" % jq_version
            ],
        )

    native.register_toolchains(
        "@rules_databricks//toolchains/databricks:databricks_linux_toolchain",
    )

    if "databricks_config" not in excludes:
        toolchain_configure(name = "databricks_config")
