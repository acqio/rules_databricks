load(
    "//databricks/private/common:common.bzl",
    "CHECK_CONFIG_FILE",
    "DATABRICKS_TOOLCHAIN",
    "DBFS_PROPERTIES",
)
load("//databricks/private/common:utils.bzl", "utils")
load("//databricks/private:providers/providers.bzl", "ConfigureInfo", "FsInfo")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")

def _aspect_files(ctx):
    return struct(
        bazel_files = [file for file in ctx.files.files],
        dbfs_files_dirname = paths.join(
            DBFS_PROPERTIES["dbfs_basepath"],
            DBFS_PROPERTIES["dbfs_prefix_filepath"],
        ),
    )

def _impl(ctx):
    properties = utils.toolchain_properties(ctx, DATABRICKS_TOOLCHAIN)
    aspects = _aspect_files(ctx)
    api_cmd = ctx.attr._command
    cmd = []

    configure = ctx.attr.configure
    configure_info = configure[ConfigureInfo]
    reader_config_file = ctx.attr._config_file_reader.files_to_run.executable.short_path

    runfiles = ctx.attr._config_file_reader.files.to_list()
    transitive_files = (
        properties.toolchain_info_file_list +
        properties.jq_info_file_list +
        configure[DefaultInfo].default_runfiles.files.to_list()
    )

    variables = [
        'CLI="%s"' % properties.cli,
        'CMD="%s %s"' % (ctx.attr._api, api_cmd),
        'export DATABRICKS_CONFIG_FILE="%s"' % configure_info.config_file,
        'DEFAULT_OPTIONS="--profile %s"' % configure_info.profile,
        'JQ_TOOL="%s"' % properties.jq_tool,
        'READER_CONFIG_FILE="%s"' % reader_config_file,
    ]

    cmd_template = "exe $CLI $CMD $DEFAULT_OPTIONS {OPTIONS} {ARGS}"

    fsinfo_stampfile = ""
    if ctx.attr.stamp:
        stamp_file = ctx.actions.declare_file(ctx.attr.name + ".stamp")
        runfiles.append(stamp_file)
        fsinfo_stampfile = stamp_file
        utils.resolve_stamp(ctx, ctx.attr.stamp.strip(), stamp_file)
        variables.append('STAMP="$(cat %s)"' % stamp_file.short_path)

    fsinfo_file = []
    fsinfo_filespath = []

    for aspect in aspects.bazel_files:
        file_basename = aspect.basename
        fsinfo_file.append(aspect)
        runfiles.append(aspect)
        dirname = paths.dirname(aspect.path)
        local_path = aspect.short_path

        if not aspect.is_source:
            dirname = paths.dirname(aspect.short_path)
        else:
            local_path = aspect.path

        if ctx.attr.stamp:
            file_basename = "${STAMP}-" + aspect.basename

        dbfs_filepath = paths.normalize(paths.join(aspects.dbfs_files_dirname + paths.join(dirname, file_basename)))
        fsinfo_filespath.append(dbfs_filepath)

        OPTIONS = ""
        ARGS = ""

        if api_cmd == "ls":
            OPTIONS = "-l --absolute"
            ARGS = "%s" % (dbfs_filepath)

        if api_cmd == "rm":
            ARGS = "%s" % (dbfs_filepath)

        if api_cmd == "cp":
            OPTIONS = "--overwrite"
            ARGS = "%s %s" % (paths.normalize(local_path), dbfs_filepath)

        cmd.append(cmd_template.format(OPTIONS = OPTIONS, ARGS = ARGS))

    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._resolve_tpl,
        substitutions = {
            "%{VARIABLES}": "\n".join(variables),
            "%{CONDITIONS}": CHECK_CONFIG_FILE,
            "%{CMD}": " && ".join(cmd),
        },
    )

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(
                files = runfiles,
                transitive_files = depset(transitive_files),
            ),
            executable = ctx.outputs.executable,
        ),
        FsInfo(
            files = depset(fsinfo_file),
            dbfs_files_path = fsinfo_filespath,
            stamp_file = fsinfo_stampfile,
        ),
    ]

_common_attr = {
    "_api": attr.string(
        default = "libraries",
    ),
    "_config_file_reader": attr.label(
        default = Label("//databricks/private/cmd/config_file_reader:main"),
        executable = True,
        cfg = "host",
    ),
    "_resolve_tpl": attr.label(
        default = utils.resolve_tpl,
        allow_single_file = True,
    ),
    "_stamper": attr.label(
        default = Label("//databricks/private/cmd/stamper:stamper"),
        executable = True,
        cfg = "host",
    ),
    "configure": attr.label(
        mandatory = True,
        providers = [ConfigureInfo],
    ),
    "files": attr.label_list(
        mandatory = True,
        allow_files = [".jar", ".py", ".sh"],
        allow_empty = False,
    ),
    "stamp": attr.string(
        default = "",
    ),
}

_fs_ls = rule(
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    implementation = _impl,
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "ls"),
        },
    ),
)

_fs_cp = rule(
    implementation = _impl,
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "cp"),
        },
    ),
)

_fs_rm = rule(
    implementation = _impl,
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "rm"),
        },
    ),
)

def fs(name, **kwargs):
    if "stamp" in kwargs:
        stamp = kwargs["stamp"].strip()
        if not stamp or not utils.check_stamping_format(stamp):
            fail(
                "The stamp attribute cannot be an empty string " +
                "or is incorrectly formatted (eg {BUILD_TIMESTAMP}): %s" % stamp,
            )

    _fs_ls(name = name, **kwargs)
    _fs_ls(name = name + ".ls", **kwargs)
    _fs_cp(name = name + ".cp", **kwargs)
    _fs_rm(name = name + ".rm", **kwargs)
