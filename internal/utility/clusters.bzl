load("//internal/utils:utils.bzl", "utils", "dirname", "join")
load(":providers.bzl", "FsInfo", "ConfigureInfo")
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

_common_attr  = {
    "_script_tpl": attr.label(
        default = Label("//internal/utility:script.sh.tpl"),
        allow_single_file = True,
    )
}

def _get_impl():
    toolchain_info = ctx.toolchains[_DATABRICKS_TOOLCHAIN].info
    databricks_cli = toolchain_info.tool_target[DefaultInfo].files_to_run.executable.short_path

    print (toolchain_info.tool_target[DefaultInfo].files_to_run.executable.short_path)
    jq_info = toolchain_info.jq_tool_target[DefaultInfo]
    cluster_info_jsonfile = ctx.actions.declare_file(cluster_name + "_cluster_info.json")
    ctx.actions.write(cluster_info_jsonfile, "algumacoisa")

    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._script_tpl,
        substitutions = {
            "%{CLI}": databricks_cli,
            "%{CLI_OPTIONS}": "--profile %s" % profile,
            "%{CLUSTER_NAME}": cluster_name,
            "%{JQ_PATH}": jq_info.files_to_run.executable.path,
            "%{CLI_COMMAND}": "clusters list",
            "%{CLUSTER_INFO_JSONFILE}": cluster_info_jsonfile.path
        }
    )

    runfiles = ctx.runfiles(files = toolchain_info.tool_target.files.to_list() + jq_info.files.to_list())

    return [
        DefaultInfo(
            runfiles = runfiles,
            files = depset([ctx.outputs.executable]),
        )
    ]

get = rule(
    implementation = _get_impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN,],
    attrs = utils.add_dicts(
        _common_attr,
        {
            "configure": attr.label(
                mandatory = True,
                providers = [ConfigureInfo]
            ),
        },
    ),
)
