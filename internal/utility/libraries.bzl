load(
    "//internal/utils:utils.bzl",
    "utils", "dirname", "join_path", "resolve_stamp", "toolchain_properties", "resolve_config_file"
)
load("//internal/utils:providers.bzl", "FsInfo", "ConfigureInfo")
load("//internal/utils:common.bzl", "DBFS_PROPERTIES", "DATABRICKS_API_COMMAND_ALLOWED", "CMD_CONFIG_FILE_STATUS", "CMD_CLUSTER_INFO")
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

_common_attr = {
    "_script_tpl": attr.label(
        default = Label("//internal/utility:script.sh.tpl"),
        allow_single_file = True,
    ),
    "_reading_from_file": attr.label(
        default = Label("//internal/utils/reading_from_file:reading_from_file.par"),
        executable = True,
        cfg = "host"
    ),
    "_api": attr.string(
        default = "libraries",
    ),
    "dbfs": attr.label(
        mandatory = False,
        providers = [FsInfo]
    ),
    "maven_info": attr.string_dict(
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
        'DEFAULT_ARGS="--profile %s"'% ctx.attr.configure[ConfigureInfo].profile,
        'JQ_TOOL="%s"'% properties.jq_tool,
        'CLUSTER_NAME="%s"'% ctx.attr.configure[ConfigureInfo].cluster_name,
        'CLUSTER_ID=$(${CLI} clusters list ${DEFAULT_ARGS} --output JSON | ' + \
            '${JQ_TOOL} -r \'(.clusters[] | select (.cluster_name=="\'${CLUSTER_NAME}\'")).cluster_id\')'
    ]

    configure_info = ctx.attr.configure[ConfigureInfo]
    runfiles.append(configure_info.config_file_info)
    variables.append('CONFIG_FILE_INFO="$(cat %s)"' % configure_info.config_file_info.short_path)

    s_cli_format = "${CLI}"
    s_default_options = "${DEFAULT_ARGS}"
    cmd_format = " {cli} {cmd} {default_options} {options} {dbfs_src}"

    if api_cmd == "install":
        if ctx.attr.dbfs:
            fs_info = ctx.attr.dbfs[FsInfo]

            if fs_info.stamp_file:
                transitive_files.append(fs_info.stamp_file)
                variables.append('STAMP="$(cat %s)"' % fs_info.stamp_file.short_path)

            for dbfs_src_path in fs_info.dbfs_srcs_path:
                cmd.append(
                        cmd_format.format(
                            cli = s_cli_format,
                            cmd = "%s %s" % (ctx.attr._api,api_cmd),
                            default_options = s_default_options,
                            options = "--cluster-id ${CLUSTER_ID} --jar" ,
                            dbfs_src = dbfs_src_path
                        )
                    )
        # elif ctx.attr.maven_info:
        #     print(a)

    if api_cmd == "cluster-status":
        cmd.append(
            cmd_format.format(
                cli = s_cli_format,
                cmd = "%s %s" % (ctx.attr._api,api_cmd),
                default_options = s_default_options,
                options = "--cluster-id ${CLUSTER_ID}" ,
                dbfs_src = ""
            )
        )


    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._script_tpl,
        substitutions = {
            "%{VARIABLES}": '\n'.join(variables),
            "%{CONDITIONS}": CMD_CONFIG_FILE_STATUS + CMD_CLUSTER_INFO,
            "%{PRE_CMD}" : "# exec '%s'" % ctx.attr.dbfs[DefaultInfo].files_to_run.executable.short_path,
            "%{CMD}": ' '.join(cmd)
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
