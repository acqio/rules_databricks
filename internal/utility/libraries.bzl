load(":providers.bzl", "FsInfo", "ConfigureInfo")
load("//internal/utils:utils.bzl", "utils", "toolchain_properties")
load("//internal/utils:common.bzl", "CMD_CONFIG_FILE_STATUS", "CMD_CLUSTER_INFO")
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

_common_attr = {
    "_script_tpl": attr.label(
        default = Label("//internal/utility:script.sh.tpl"),
        allow_single_file = True,
    ),
    "_api": attr.string(
        default = "libraries",
    ),
    "dbfs": attr.label(
        mandatory = False,
        providers = [FsInfo]
    ),
    "maven_info": attr.string_list_dict(
        mandatory = False,
    ),
    "configure": attr.label(
        mandatory = True,
        providers = [ConfigureInfo]
    ),
}

def _impl(ctx):

    properties = toolchain_properties(ctx, _DATABRICKS_TOOLCHAIN)
    api_cmd = ctx.attr._command
    cmd=[]
    runfiles = []
    transitive_files = []
    transitive_files+= (properties.toolchain_info_file_list + properties.jq_info_file_list)

    variables = [
        'CLI="%s"' % properties.cli,
        'JQ_TOOL="%s"' % properties.jq_tool,
        'DEFAULT_OPTIONS="--profile %s"' % ctx.attr.configure[ConfigureInfo].profile,
        'CLUSTER_NAME="%s"' % ctx.attr.configure[ConfigureInfo].cluster_name,
    ]
    cmd_format = "$CLI {cmd} $DEFAULT_OPTIONS --cluster-id $CLUSTER_ID {options}"

    configure_info = ctx.attr.configure[ConfigureInfo]
    runfiles.append(configure_info.config_file_info)
    variables.append('CONFIG_FILE_INFO="$(cat %s)"' % configure_info.config_file_info.short_path)


    if api_cmd == "install":
        if ctx.attr.dbfs:
            dbfs = ctx.attr.dbfs

            if dbfs[FsInfo].stamp_file:
                transitive_files.append(dbfs[FsInfo].stamp_file)
                variables.append('STAMP="$(cat %s)"' % dbfs[FsInfo].stamp_file.short_path)

            transitive_files.append(dbfs[DefaultInfo].files_to_run.executable)
            cmd.append("exec '%s';" % dbfs[DefaultInfo].files_to_run.executable.short_path)

            for dbfs_src_path in dbfs[FsInfo].dbfs_srcs_path:
                cmd.append(
                        cmd_format.format(
                            cmd = "%s %s" % (ctx.attr._api,api_cmd),
                            options = "--jar %s" % dbfs_src_path
                        )
                    )
        if ctx.attr.maven_info:
            maven_info = ctx.attr.maven_info.items()
            for repo, coordinates in maven_info:
                for coordinate in coordinates:
                    cmd.append(
                        cmd_format.format(
                            cmd = "%s %s" % (ctx.attr._api,api_cmd),
                            options = "--maven-repo %s --maven-coordinates %s" % (repo, coordinate),
                        )
                    )

    if api_cmd == "cluster-status":
        cmd.append("echo $CLUSTER_STATUS_LIBRARIES | $JQ_TOOL")


    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._script_tpl,
        substitutions = {
            "%{VARIABLES}": '\n'.join(variables),
            "%{CONDITIONS}": CMD_CONFIG_FILE_STATUS + CMD_CLUSTER_INFO,
            "%{CMD}": ' && '.join(cmd)
        }
    )

    return [
            DefaultInfo(
                runfiles = ctx.runfiles(
                    files = runfiles,
                    transitive_files = depset(transitive_files)
                ),
            ),
        ]


_libraries_cluster_status = rule(
    implementation = _impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = utils.add_dicts(
        _common_attr,
        {
            "_command": attr.string(default = "cluster-status")
        },
    ),
)

_libraries_install = rule(
    implementation = _impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = utils.add_dicts(
        _common_attr,
        {
            "_command": attr.string(default = "install")
        },
    ),
)


def libraries (name, **kwargs):
    _libraries_cluster_status(name = name, **kwargs)
    _libraries_cluster_status(name = name + ".cluster_status", **kwargs)
    _libraries_install(name = name + ".install",**kwargs)
