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
load("//databricks/private:providers/providers.bzl", "ConfigureInfo")
load("//databricks/private/common:common.bzl", "DATABRICKS_TOOLCHAIN")
load("//databricks/private/common:utils.bzl", "utils")

def _impl(ctx):
    cluster_name = ctx.attr.cluster_name or ""
    profile = ctx.attr.profile or ""
    if not cluster_name.strip():
        fail("The cluster name value is mandatory.")
    if not profile:
        fail("The profile value is mandatory.")

    files = []

    if utils.check_stamping_format(cluster_name):
        cluster_name_file = ctx.actions.declare_file(ctx.label.name + ".cluster-name")
        utils.resolve_stamp(ctx, cluster_name, cluster_name_file)
        cluster_name = "$(cat \"%s\")" % cluster_name_file.short_path
        files.append(cluster_name_file)

    if utils.check_stamping_format(profile):
        profile_file = ctx.actions.declare_file(ctx.label.name + ".profile")
        utils.resolve_stamp(ctx, profile, profile_file)
        profile = "$(cat \"%s\")" % profile_file.short_path
        files.append(profile_file)

    return [
        ConfigureInfo(
            config_file = ctx.toolchains[DATABRICKS_TOOLCHAIN].info.config_file,
            cluster_name = cluster_name,
            profile = profile,
        ),
        DefaultInfo(
            runfiles = ctx.runfiles(
                files = files,
            ),
        ),
    ]

configure = rule(
    implementation = _impl,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = {
        "_stamper": attr.label(
            default = Label("//databricks/private/cmd/stamper:stamper"),
            executable = True,
            cfg = "host",
        ),
        "cluster_name": attr.string(
            mandatory = True,
        ),
        "profile": attr.string(
            default = "DEFAULT",
            mandatory = True,
        ),
    },
)

def _impl_alias(repository_ctx):
    repository_ctx.file(
        "BUILD.bazel",
        content = """
load("@rules_databricks//:index.bzl", "databricks_configure")

databricks_configure(
    name = "configure",
    cluster_name = "{cluster_name}",
    profile = "{profile}",
    visibility = ["//visibility:public"],
)
""".format(
            cluster_name = repository_ctx.attr.cluster_name,
            profile = repository_ctx.attr.profile,
        ),
    )

configure_alias = repository_rule(
    implementation = _impl_alias,
    attrs = {
        "cluster_name": attr.string(mandatory = True),
        "profile": attr.string(default = "DEFAULT", mandatory = True),
    },
)
