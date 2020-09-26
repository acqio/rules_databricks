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
        "config_file": "A configured path to the Databricks configuration file. " +
                       "If databricks_config_file is not specified, the value " +
                       "of the DATABRICKS_CONFIG_FILE environment variable will be used. " +
                       "DATABRICKS_CONFIG_FILE is not defined, the default set for the " +
                       "databricks tool (typically, the home directory) will be used.",
        "jq_tool_target": "A jq executable target to downloaded.",
        "tool_path": "Path to the databricks executable",
        "tool_target": "A databricks cli executable target built from source or downloaded.",
    },
)

def _databricks_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        info = DataBricksToolchainInfo(
            config_file = ctx.attr.config_file,
            jq_tool_target = ctx.attr.jq_tool_target,
            tool_path = ctx.attr.tool_path,
            tool_target = ctx.attr.tool_target,
        ),
    )
    return [toolchain_info]

# Rule used by the databricks toolchain rule to specify a path to the databricks
# binary
databricks_toolchain = rule(
    implementation = _databricks_toolchain_impl,
    attrs = {
        "jq_tool_target": attr.label(
            doc = "Target to build jq from source.",
            executable = True,
            cfg = "host",
        ),
        "config_file": attr.string(
            default = "",
            doc = """A configured path to the Databricks configuration file.
                  If databricks_config_file is not specified, the value
                  of the DATABRICKS_CONFIG_FILE environment variable will be used.
                  DATABRICKS_CONFIG_FILE is not defined, the default set for the
                  databricks tool (typically, the home directory) will be used.""",
        ),
        "tool_path": attr.string(
            doc = "Path to the binary.",
        ),
        "tool_target": attr.label(
            doc = "Target to build databicks_cli from source.",
            executable = True,
            cfg = "host",
        ),
    },
)
