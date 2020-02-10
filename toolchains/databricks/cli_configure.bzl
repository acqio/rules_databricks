def _cli_configure_impl(repository_ctx):

    tool_path = ""
    if repository_ctx.attr.tool_path:
        tool_path = repository_ctx.attr.tool_path
    elif repository_ctx.which("databricks"):
        tool_path = repository_ctx.which("databricks")

    client_config = repository_ctx.attr.client_config or "~/.databrickscfg"
    profile = repository_ctx.attr.profile or "DEFAULT"
    tool_target = "@rules_databricks//databricks:cli"
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
cli_configure = repository_rule(
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
    implementation = _cli_configure_impl,
)
