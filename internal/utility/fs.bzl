load("//internal/utils:utils.bzl", "utils", "dirname", "join_path", "resolve_stamp")
load("//internal/utils:providers.bzl", "FsInfo", "ConfigureInfo")
load("//internal/utils:common.bzl", "DBFS_PROPERTIES", "DATABRICKS_API_COMMAND_ALLOWED")
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

# def _symlink_impl(ctx):
#     symlink = ctx.actions.declare_symlink(ctx.label.name)
#     ctx.actions.symlink(symlink, ctx.attr.link_target)
#     return DefaultInfo(files = depset([symlink]))

# symlink = rule(implementation = _symlink_impl, attrs = {"link_target": attr.string()})

# def _write_impl(ctx):
#     output = ctx.actions.declare_file(ctx.label.name)
#     ctx.actions.write(output, ctx.attr.contents)
#     return DefaultInfo(files = depset([output]))
# write = rule(implementation = _write_impl, attrs = {"contents": attr.string()})

def _aspect_srcs(ctx):

    return struct(
        bazel_srcs = [src for src in ctx.files.srcs],
        dbfs_srcs_dirname =  join_path(DBFS_PROPERTIES["dbfs_path_jars"], DBFS_PROPERTIES["dbfs_filepath_prefix"])
    )

_common_attr  = {
    "_script_tpl": attr.label(
        default = Label("//internal/utility:fs.sh.tpl"),
        allow_single_file = True,
    ),
    "_stamper": attr.label(
        default = Label("//internal/utils/stamper:stamper"),
        cfg = "host",
        executable = True,
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

def _properties(ctx):

    toolchain_info = ctx.toolchains[_DATABRICKS_TOOLCHAIN].info
    jq_info = toolchain_info.jq_tool_target[DefaultInfo]

    return struct(
        toolchain_info = toolchain_info,
        toolchain_info_file_list = toolchain_info.tool_target.files.to_list(),
        profile = ctx.attr.configure[ConfigureInfo].profile,
        cli = toolchain_info.tool_target[DefaultInfo].files_to_run.executable.short_path,
        cluster_name = ctx.attr.configure[ConfigureInfo].cluster_name,
        jq_info =  jq_info,
        jq_info_file_list =  jq_info.files.to_list()
    )

def _impl(ctx):
    properties = _properties(ctx)
    aspects = _aspect_srcs(ctx)
    cmd=[]
    api_cmd = ctx.attr._command

    extra_runfiles = []

    variables = [
        'CLI="%s"' % properties.cli,
        'DEFAULT_ARGS="--profile %s"'% properties.profile,
        'CLUSTER_NAME="%s"'% properties.cluster_name,
    ]

    if ctx.attr.stamp:
        stamp_file = ctx.actions.declare_file(ctx.attr.name + ".stamp")
        resolve_stamp(ctx, ctx.attr.stamp.strip(), stamp_file)
        extra_runfiles.append(stamp_file)
        variables.append('STAMP="$(cat %s)"' % stamp_file.short_path)

    s_cli_format = "${CLI}"
    s_default_options = "${DEFAULT_ARGS}"
    cmd_format = "{cli} {cmd} {default_options} {options} {src} {dbfs_src}"

    FsInfo_srcs_srcs_path=[]

    for aspect in aspects.bazel_srcs:
        src_basename = aspect.basename

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
            "%{CMD}": '; \n'.join(cmd)
        }
    )

    print(aspects.bazel_srcs)
    print(FsInfo_srcs_srcs_path)

    return [
            DefaultInfo(
                runfiles = ctx.runfiles(
                    files = ctx.files.srcs + extra_runfiles,
                    transitive_files = depset(properties.toolchain_info_file_list + properties.jq_info_file_list)
                ),
            ),
            FsInfo(
                srcs = aspects.bazel_srcs,
                dbfs_srcs_path = aspects.dbfs_srcs_dirname,
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
