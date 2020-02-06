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
"""
This module defines azure toolchain rules
"""

DataBricksToolchainInfo = provider(
    doc = "Docker toolchain rule parameters",
    fields = {
        "client_config": "A custom directory for the databricks client " +
                         "config.json. If DATABRICKS_CONFIG is not specified, " +
                         "the value of the DATABRICKS_CONFIG environment variable " +
                         "will be used. DATABRICKS_CONFIG is not defined, the " +
                         "home directory will be used.",
        "tool_path": "Path to the databricks executable",
        "tool_target": "A databricks cli executable target built from source or downloaded.",
        "profile": "The name profile to client_config using",
        "jq_tool_target": "A jq executable target to downloaded.",
    },
)

def _databricks_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        info = DataBricksToolchainInfo(
            client_config = ctx.attr.client_config,
            tool_path = ctx.attr.tool_path,
            tool_target = ctx.attr.tool_target,
            profile = ctx.attr.profile,
            jq_tool_target = ctx.attr.jq_tool_target
        ),
    )
    return [toolchain_info]

# Rule used by the databricks toolchain rule to specify a path to the databricks
# binary
databricks_toolchain = rule(
    implementation = _databricks_toolchain_impl,
    attrs = {
        "client_config": attr.string(
            default = "",
            doc = "A custom directory for the databricks client config.json. If " +
                  "DATABRICKS_CONFIG is not specified, the value of the " +
                  "DATABRICKS_CONFIG environment variable will be used. " +
                  "DATABRICKS_CONFIG is not defined, the home directory will be " +
                  "used.",
        ),
        "tool_path": attr.string(
            doc = "Path to the binary.",
        ),
        "tool_target": attr.label(
            doc = "Target to build databicks_cli from source.",
            executable = True,
            cfg = "host",
        ),
        "profile": attr.string(
            doc = ""
        ),
        "jq_tool_target": attr.label(
            doc = "Target to build jq from source.",
            executable = True,
            cfg = "host",
        ),
    },
)

def _toolchain_configure_impl(repository_ctx):

    tool_path = ""
    if repository_ctx.attr.tool_path:
        tool_path = repository_ctx.attr.tool_path
    elif repository_ctx.which("databricks"):
        tool_path = repository_ctx.which("databricks")

    client_config = repository_ctx.attr.client_config or "~/.databrickscfg"
    profile = repository_ctx.attr.profile or "DEFAULT"
    tool_target = "@rules_databricks//repositories:cli"
    jq_tool_target = "@jq//file:file"

    repository_ctx.template(
        "BUILD.bazel",
        Label("@rules_databricks//toolchains/databricks:BUILD.bazel.tpl"),
        {
            "%{DATABRICKS_CONFIG}": "%s" % client_config,
            "%{DATABRICKS_TOOL_PATH}": "%s" % tool_path,
            "%{DATABRICKS_TOOL_TARGET}": tool_target,
            "%{DATABRICKS_PROFILE}": "%s" % profile,
            "%{JQ_TOOL_TARGET}": "%s" % jq_tool_target
        },
        False,
    )

# Repository rule to generate a databricks_toolchain target
toolchain_configure = repository_rule(
    attrs = {
        "client_config": attr.string(
            mandatory = False,
            doc = "A custom directory for the databricks client " +
                  "config.json. If DATABRICKS_CONFIG is not specified, the value " +
                  "of the DATABRICKS_CONFIG environment variable will be used. " +
                  "DATABRICKS_CONFIG is not defined, the default set for the " +
                  "databricks tool (typically, the home directory) will be " +
                  "used.",
        ),
        "tool_path": attr.string(
            mandatory = False,
            doc = "The full path to the databricks binary. If not specified, it will " +
                  "be searched for in the path. If not available, running commands " +
                  "that require databricks (e.g., incremental load) will fail.",
        ),
        "profile": attr.string(
            mandatory = False,
            doc = ""
        )
    },
    environ = [
        "PATH",
    ],
    implementation = _toolchain_configure_impl,
)
