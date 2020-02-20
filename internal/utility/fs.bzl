load(
    "//internal/utils:utils.bzl",
    "utils", "dirname", "join_path", "resolve_stamp", "toolchain_properties",
)
load("//internal/utils:providers.bzl", "FsInfo", "ConfigureInfo")
load("//internal/utils:common.bzl", "DBFS_PROPERTIES", "CMD_CONFIG_FILE_STATUS")
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

def _aspect_jars(ctx):

    return struct(
        bazel_jars = [jar for jar in ctx.files.jars],
        dbfs_jars_dirname =  join_path(DBFS_PROPERTIES["dbfs_jars_basepath"], DBFS_PROPERTIES["dbfs_prefix_filepath"])
    )

_common_attr  = {
    "_script_tpl": attr.label(
        default = Label("//internal/utility:script.sh.tpl"),
        allow_single_file = True,
    ),
    "_stamper": attr.label(
        default = Label("//internal/utils/stamper:stamper.par"),
        executable = True,
        cfg = "host",
    ),
    "_reading_from_file": attr.label(
        default = Label("//internal/utils/reading_from_file:reading_from_file.par"),
        executable = True,
        cfg = "host"
    ),
    "_api": attr.string(
        default = "fs",
    ),
    "jars": attr.label_list(
        mandatory = True,
        allow_files = True,
        # allow_files = [".jar"],
        allow_empty = False,
    ),
    "configure": attr.label(
        mandatory = True,
        providers = [ConfigureInfo]
    ),
    "stamp" : attr.string(
        default = ""
    ),
}

def _impl(ctx):
    properties = toolchain_properties(ctx, _DATABRICKS_TOOLCHAIN)
    aspects = _aspect_jars(ctx)
    api_cmd = ctx.attr._command
    cmd=[]
    runfiles = []

    variables = [
        'CLI="%s"' % properties.cli,
        'DEFAULT_ARGS="--profile %s"'% ctx.attr.configure[ConfigureInfo].profile,
        'JQ_TOOL="%s"'% properties.jq_tool,
    ]

    config_file_info = ctx.attr.configure[ConfigureInfo].config_file_info
    runfiles.append(config_file_info)
    variables.append('CONFIG_FILE_INFO="$(cat %s)"' % config_file_info.short_path)

    if ctx.attr.stamp:
        stamp_file = ctx.actions.declare_file(ctx.attr.name + ".stamp")
        resolve_stamp(ctx, ctx.attr.stamp.strip(), stamp_file)
        runfiles.append(stamp_file)
        variables.append('STAMP="$(cat %s)"' % stamp_file.short_path)

    s_cli_format = "${CLI}"
    s_default_options = "${DEFAULT_ARGS}"
    cmd_format = "# {cli} {cmd} {default_options} {options} {jar} {dbfs_jar}"

    FsInfo_jars_jars_path=[]

    for aspect in aspects.bazel_jars:
        jar_basename = aspect.basename
        runfiles.append(aspect)
        if ctx.attr.stamp:
            jar_basename = "${STAMP}-" + aspect.basename

        s_dbfs_jar = aspects.dbfs_jars_dirname + aspect.dirname + "/" + jar_basename
        FsInfo_jars_jars_path.append(s_dbfs_jar)

        if api_cmd in ["ls","cp"]:
            if api_cmd == "cp":
                cmd.append(
                    cmd_format.format(
                        cli = s_cli_format,
                        cmd = "%s %s" % (ctx.attr._api,api_cmd),
                        default_options = s_default_options,
                        options = "--overwrite",
                        jar = aspect.path,
                        dbfs_jar = s_dbfs_jar
                    )
                )
            cmd.append(
                cmd_format.format(
                    cli = s_cli_format,
                    cmd = "%s %s" % (ctx.attr._api, "ls"),
                    default_options = s_default_options,
                    options = "--absolute -l",
                    jar = "",
                    dbfs_jar = s_dbfs_jar
                )
            )

        if api_cmd == "rm":
            cmd.append(
                cmd_format.format(
                    cli = s_cli_format,
                    cmd = "%s %s" % (ctx.attr._api, api_cmd),
                    default_options = s_default_options,
                    options = "",
                    jar = "",
                    dbfs_jar = s_dbfs_jar
                )
            )

    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._script_tpl,
        substitutions = {
            "%{VARIABLES}": '\n'.join(variables),
            "%{CONDITIONS}": CMD_CONFIG_FILE_STATUS,
            "%{PRE_CMD}" : "",
            "%{CMD}": ' ;'.join(cmd)
        }
    )

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(
                files = runfiles,
                transitive_files = depset(
                    properties.toolchain_info_file_list + properties.jq_info_file_list
                )
            ),
            executable = ctx.outputs.executable
        ),
        FsInfo(
            jars = aspects.bazel_jars,
            dbfs_jars_path = FsInfo_jars_jars_path,
            stamp_file = stamp_file
        )
    ]


_fs_ls = rule(
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    implementation = _impl,
    attrs = utils.add_dicts(
        _common_attr,
        {
            "_command": attr.string(default = "ls")
        },
    ),
)

_fs_cp = rule(
    implementation = _impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = utils.add_dicts(
        _common_attr,
        {
            "_command": attr.string(default = "cp")
        },
    ),
)

_fs_rm = rule(
    implementation = _impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = utils.add_dicts(
        _common_attr,
        {
            "_command": attr.string(default = "rm")
        },
    ),
)

def fs(name, **kwargs):

    if "directory" in kwargs:
        if not kwargs["directory"].strip():
            fail ("The directory attribute cannot be an empty string.")
    if "stamp" in kwargs:
        stamp = kwargs["stamp"].strip()
        if not stamp:
            fail ("The stamp attribute cannot be an empty string.")

        if not (
                (
                    stamp.count('{') == 1 and stamp.rindex("{") == 0) and (
                    stamp.count('}') == 1 and stamp.rindex("}") == stamp.find('}')
                )
            ):
            fail ("The stamp string is badly formatted (eg {BUILD_TIMESTAMP}):\n" + str(stamp))

    _fs_ls(name = name, **kwargs)
    _fs_ls(name = name + ".ls", **kwargs)
    _fs_cp(name = name + ".cp",**kwargs)
    _fs_rm(name = name + ".rm",**kwargs)
