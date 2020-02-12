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
        "jq_tool_target": "A jq executable target to downloaded.",
    },
)

def _databricks_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        info = DataBricksToolchainInfo(
            client_config = ctx.attr.client_config,
            tool_path = ctx.attr.tool_path,
            tool_target = ctx.attr.tool_target,
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
        "jq_tool_target": attr.label(
            doc = "Target to build jq from source.",
            executable = True,
            cfg = "host",
        ),
    },
)
