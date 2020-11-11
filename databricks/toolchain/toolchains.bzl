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
    return [
        platform_common.ToolchainInfo(
            info = DataBricksToolchainInfo(
                config_file = ctx.attr.config_file,
                jq_tool_target = ctx.attr.jq_tool_target,
                tool_path = ctx.attr.tool_path,
                tool_target = ctx.attr.tool_target,
            ),
        ),
        platform_common.TemplateVariableInfo({
            "DBK_TOOL_PATH": str(ctx.attr.tool_path),
            "DBK_TOOL_TARGET": str(ctx.attr.tool_target),
        }),
    ]

# Rule used by the databricks toolchain rule to specify a path to the databricks
# binary
databricks_toolchain = rule(
    implementation = _databricks_toolchain_impl,
    attrs = {
        "config_file": attr.string(
            default = "",
            doc = """A configured path to the Databricks configuration file.
                  If databricks_config_file is not specified, the value
                  of the DATABRICKS_CONFIG_FILE environment variable will be used.
                  DATABRICKS_CONFIG_FILE is not defined, the default set for the
                  databricks tool (typically, the home directory) will be used.""",
        ),
        "jq_tool_target": attr.label(
            doc = "Target to build jq from source.",
            executable = True,
            cfg = "host",
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
