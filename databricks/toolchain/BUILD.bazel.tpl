"""
This BUILD file is auto-generated from databricks/toolchain/BUILD.bazel.tpl
"""
package(default_visibility = ["//visibility:public"])

load("@rules_databricks//databricks/toolchain:toolchains.bzl", "databricks_toolchain")

databricks_toolchain(
    name = "toolchain",
    config_file = "%{CONFIG_FILE}",
    jq_tool_target = "%{JQ_TOOL_TARGET}",
    tool_path = "%{TOOL_PATH}",
    tool_target = "%{TOOL_TARGET}",
)
