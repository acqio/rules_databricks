def _toolchain_configure_impl(repository_ctx):
    tool_path = ""
    if repository_ctx.attr.tool_path:
        tool_path = repository_ctx.attr.tool_path
    elif repository_ctx.which("databricks"):
        tool_path = repository_ctx.which("databricks")

    config_file = ""
    if repository_ctx.attr.config_file:
        config_file = repository_ctx.attr.config_file
    elif "DATABRICKS_CONFIG_FILE" in repository_ctx.os.environ:
        config_file = repository_ctx.os.environ["DATABRICKS_CONFIG_FILE"]
    elif "HOME" in repository_ctx.os.environ:
        config_file = repository_ctx.os.environ["HOME"] + "/.databrickscfg"
    else:
        config_file = "~/.databrickscfg"

    tool_target = "@rules_databricks//databricks:cli"
    jq_tool_target = "@jq//file:file"

    repository_ctx.template(
        "BUILD.bazel",
        Label("@rules_databricks//databricks/toolchain:BUILD.bazel.tpl"),
        {
            "%{CONFIG_FILE}": "%s" % config_file,
            "%{JQ_TOOL_TARGET}": "%s" % jq_tool_target,
            "%{TOOL_PATH}": "%s" % tool_path,
            "%{TOOL_TARGET}": tool_target,
        },
        False,
    )

# Repository rule to generate a databricks_toolchain target
toolchain_configure = repository_rule(
    implementation = _toolchain_configure_impl,
    attrs = {
        "config_file": attr.string(
            mandatory = False,
            doc = """A configured path to the Databricks configuration file.
                  If databricks_config_file is not specified, the value
                  of the DATABRICKS_CONFIG_FILE environment variable will be used.
                  DATABRICKS_CONFIG_FILE is not defined, the default set for the
                  databricks tool (typically, the home directory) will be used.""",
        ),
        "tool_path": attr.string(
            mandatory = False,
            doc = """The full path to the databricks binary. If not specified, it will
                  be searched for in the path. If not available, running commands
                  that require databricks (e.g., incremental load) will fail.""",
        ),
    },
    environ = [
        "PATH",
    ],
)
