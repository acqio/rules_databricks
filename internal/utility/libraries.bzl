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
    "_reading_yaml_file": attr.label(
        default = Label("//internal/utils/reading_yaml_file:main.par"),
        executable = True,
        cfg = "host",
    ),
    "_api": attr.string(
        default = "libraries",
    ),
    "jar": attr.label(
        mandatory = False,
        providers = [FsInfo]
    ),
    "bazel_deps_dependencies": attr.label(
        allow_single_file = [".yaml", ".yml"]
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
        'DEFAULT_ARGS="--profile %s"'% ctx.attr.configure[ConfigureInfo].profile,
        'JQ_TOOL="%s"'% properties.jq_tool,
        'CLUSTER_NAME="%s"'% ctx.attr.configure[ConfigureInfo].cluster_name,
    ]

    configure_info = ctx.attr.configure[ConfigureInfo]
    runfiles.append(configure_info.config_file_info)
    variables.append('CONFIG_FILE_INFO="$(cat %s)"' % configure_info.config_file_info.short_path)

    cmd_format = "$CLI {cmd} $DEFAULT_ARGS --cluster-id $CLUSTER_ID {options};"

    if api_cmd == "install":
        if ctx.attr.jar:
            fs_info = ctx.attr.jar[FsInfo]

            if fs_info.stamp_file:
                transitive_files.append(fs_info.stamp_file)
                variables.append('STAMP="$(cat %s)"' % fs_info.stamp_file.short_path)

            cmd.append("exec '%s';" % ctx.attr.jar[DefaultInfo].files_to_run.executable.short_path)

            for dbfs_src_path in fs_info.dbfs_srcs_path:
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

        if len(ctx.files.bazel_deps_dependencies) == 1:
            src = ctx.files.bazel_deps_dependencies[0]

            maven_coordinates = ctx.actions.declare_file(ctx.attr.name + ".maven-coordinates")
            args = ctx.actions.args()
            args.add(src, format = "--yaml=%s")
            args.add(ctx.attr.maven_info, format = "--maven-coordinates=%s")
            args.add(maven_coordinates, format = "--output=%s")

            transitive_files.append(maven_coordinates)
            transitive_files.append(src)

            ctx.actions.run(
                executable = ctx.executable._reading_yaml_file,
                arguments = [args],
                inputs = [src],
                tools = [ctx.executable._reading_yaml_file],
                outputs = [maven_coordinates],
                mnemonic = "BazelDepsDependencies",
            )

    if api_cmd == "cluster-status":
        cmd.append(
            cmd_format.format(
                cmd = "%s %s" % (ctx.attr._api,api_cmd),
                options = "",
            )
        )


    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._script_tpl,
        substitutions = {
            "%{VARIABLES}": '\n'.join(variables),
            "%{CONDITIONS}": CMD_CONFIG_FILE_STATUS + CMD_CLUSTER_INFO,
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
