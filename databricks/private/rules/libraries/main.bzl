load(
    "//databricks/private/common:common.bzl",
    "CHECK_CONFIG_FILE",
    "CMD_CLUSTER_INFO",
    "DATABRICKS_TOOLCHAIN",
)
load(
    "//databricks/private/common:utils.bzl",
    "utils",
)
load(
    "//databricks/private:providers/providers.bzl",
    "ConfigureInfo",
    "FsInfo",
)
load(
    "@bazel_skylib//lib:dicts.bzl",
    "dicts",
)

def _impl(ctx):
    properties = utils.toolchain_properties(ctx, DATABRICKS_TOOLCHAIN)
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

    cluster_name = ctx.attr.cluster_name
    if not cluster_name.strip():
        fail("The cluster name value is mandatory.")

    if utils.check_stamping_format(cluster_name):
        cluster_name_file = ctx.actions.declare_file(ctx.label.name + ".cluster-name")
        utils.resolve_stamp(ctx, cluster_name, cluster_name_file)
        cluster_name = "$(cat %s)" % cluster_name_file.short_path
        transitive_files.append(cluster_name_file)

    variables = [
        'CLI="%s"' % properties.cli,
        'CLUSTER_NAME="%s"' % cluster_name,
        'CMD="%s %s $@"' % (ctx.attr._api, api_cmd),
        'export DATABRICKS_CONFIG_FILE="%s"' % configure_info.config_file,
        'DEFAULT_OPTIONS="--profile %s"' % configure_info.profile,
        'JQ_TOOL="%s"' % properties.jq_tool,
        'READER_CONFIG_FILE="%s"' % reader_config_file,
    ]

    cmd_template = "exe $CLI $CMD $DEFAULT_OPTIONS {OPTIONS}"

    if api_cmd in ["install", "uninstall"]:
        if ctx.attr.dbfs:
            dbfs = ctx.attr.dbfs
            transitive_files.append(dbfs[DefaultInfo].files_to_run.executable)
            transitive_files += (dbfs[FsInfo].files.to_list())

        if dbfs[FsInfo].stamp_file:
            transitive_files.append(dbfs[FsInfo].stamp_file)
            variables += ["STAMP=$(cat %s)" % dbfs[FsInfo].stamp_file.short_path]

        if api_cmd == "install":
            cmd += ["'%s' $@" % dbfs[DefaultInfo].files_to_run.executable.short_path]

        cmd += [cmd_template.format(OPTIONS = "--jar %s" % f) for f in dbfs[FsInfo].dbfs_files_path]

        if ctx.attr.maven_info:
            for (r, cs) in ctx.attr.maven_info.items():
                for c in cs:
                    cmd_in = []
                    cmd_in += ["--maven-repo %s" % r, "--maven-coordinates %s" % c]
                    if c in ctx.attr.maven_package_exclusion:
                        cmd_in += [" ".join(["--maven-exclusion %s" % (e) for e in ctx.attr.maven_package_exclusion[c]])]

                    cmd += [
                        cmd_template.format(OPTIONS = " ".join(cmd_in)),
                    ]

    if api_cmd == "cluster-status":
        cmd += ["%s" % cmd_template.format(OPTIONS = "")]

    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._resolve_tpl,
        substitutions = {
            "%{VARIABLES}": "\n".join(variables),
            "%{CONDITIONS}": CHECK_CONFIG_FILE + CMD_CLUSTER_INFO,
            "%{CMD}": " && ".join(cmd),
        },
    )

    return [
        DefaultInfo(
            runfiles = ctx.runfiles(
                files = runfiles,
                transitive_files = depset(transitive_files),
            ),
        ),
    ]

_common_attr = {
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
    "_api": attr.string(
        default = "libraries",
    ),
    "cluster_name": attr.string(
        mandatory = True,
    ),
    "configure": attr.label(
        mandatory = True,
        providers = [ConfigureInfo],
    ),
    "dbfs": attr.label(
        mandatory = False,
        providers = [FsInfo],
    ),
    "maven_info": attr.string_list_dict(
        mandatory = False,
    ),
    "maven_package_exclusion": attr.string_list_dict(
        mandatory = False,
    ),
}

_libraries_status = rule(
    implementation = _impl,
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "cluster-status"),
        },
    ),
)

_libraries_install = rule(
    implementation = _impl,
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "install"),
        },
    ),
)

_libraries_uninstall = rule(
    implementation = _impl,
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "uninstall"),
        },
    ),
)

def libraries(name, **kwargs):
    _libraries_status(name = name, **kwargs)
    _libraries_status(name = name + ".status", **kwargs)
    _libraries_install(name = name + ".install", **kwargs)
    _libraries_uninstall(name = name + ".uninstall", **kwargs)
