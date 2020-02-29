load(
    "//internal/utils:utils.bzl",
    "utils", "join_path", "resolve_stamp", "toolchain_properties",
)
load("//internal/utils:providers.bzl", "FsInfo", "ConfigureInfo")
load("//internal/utils:common.bzl", "DBFS_PROPERTIES", "CMD_CONFIG_FILE_STATUS")
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

def _aspect_srcs(ctx):

    return struct(
        bazel_srcs = [src for src in ctx.files.srcs],
        dbfs_srcs_dirname =  join_path(
            DBFS_PROPERTIES["dbfs_srcs_basepath"], DBFS_PROPERTIES["dbfs_prefix_filepath"]
        )
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
    "_api": attr.string(
        default = "fs",
    ),
    "srcs": attr.label_list(
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
    aspects = _aspect_srcs(ctx)
    api_cmd = ctx.attr._command
    cmd=[]
    runfiles = []

    variables = [
        'CLI="%s"' % properties.cli,
        'DEFAULT_ARGS="--profile \'%s\'"'% ctx.attr.configure[ConfigureInfo].profile,
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
    cmd_format = "{cli} {cmd} {default_options} {options} {src} {dbfs_src};"

    FsInfo_srcs_srcs_path=[]

    for aspect in aspects.bazel_srcs:
        src_basename = aspect.basename
        runfiles.append(aspect)
        if ctx.attr.stamp:
            src_basename = "${STAMP}-" + aspect.basename

        s_dbfs_src = aspects.dbfs_srcs_dirname + aspect.dirname + "/" + src_basename
        FsInfo_srcs_srcs_path.append(s_dbfs_src)

        if api_cmd in ["ls","cp"]:
            if api_cmd == "cp":
                cmd.append(
                    cmd_format.format(
                        cli = s_cli_format,
                        cmd = "%s %s" % (ctx.attr._api,api_cmd),
                        default_options = s_default_options,
                        options = "--overwrite",
                        src = aspect.path,
                        dbfs_src = s_dbfs_src
                    )
                )
            cmd.append(
                cmd_format.format(
                    cli = s_cli_format,
                    cmd = "%s %s" % (ctx.attr._api, "ls"),
                    default_options = s_default_options,
                    options = "--absolute -l",
                    src = "",
                    dbfs_src = s_dbfs_src
                )
            )

        if api_cmd == "rm":
            cmd.append(
                cmd_format.format(
                    cli = s_cli_format,
                    cmd = "%s %s" % (ctx.attr._api, api_cmd),
                    default_options = s_default_options,
                    options = "",
                    src = "",
                    dbfs_src = s_dbfs_src
                )
            )

    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._script_tpl,
        substitutions = {
            "%{VARIABLES}": '\n'.join(variables),
            "%{CONDITIONS}": CMD_CONFIG_FILE_STATUS,
            "%{CMD}": ' '.join(cmd)
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
            srcs = aspects.bazel_srcs,
            dbfs_srcs_path = FsInfo_srcs_srcs_path,
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
