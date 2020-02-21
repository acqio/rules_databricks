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
load("//internal/utils:providers.bzl", "ConfigureInfo")
load("//internal/utils:utils.bzl", "resolve_config_file")
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

def _impl(ctx):
    profile = ctx.attr.profile or ""
    cluster_name = ctx.attr.cluster_name or ""
    if not profile:
        fail("The profile value is mandatory.")
    if not cluster_name.strip():
        fail("The cluster name value is mandatory.")

    config_file_info = ctx.actions.declare_file(ctx.attr.name + ".config_file_info")
    resolve_config_file(
        ctx,
        ctx.toolchains[_DATABRICKS_TOOLCHAIN].info.client_config,
        profile,
        config_file_info
    )

    return [
        DefaultInfo(
            data_runfiles = ctx.runfiles (
                transitive_files = depset([config_file_info])
            )
        ),
        ConfigureInfo(
            profile = profile,
            cluster_name = cluster_name,
            config_file_info = config_file_info
        )
    ]

configure = rule(
    implementation = _impl,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = {
        "profile": attr.string(
            default = "DEFAULT",
            mandatory = True
        ),
        "cluster_name": attr.string(
            mandatory = True
        ),
        "_reading_from_file": attr.label(
            default = Label("//internal/utils/reading_from_file:main.par"),
            executable = True,
            cfg = "host"
        ),
    }
)
