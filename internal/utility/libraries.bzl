load(":providers.bzl", "FsInfo", "ConfigureInfo")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("//internal/utils:utils.bzl", "toolchain_properties")
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
    configure_info = ctx.attr.configure[ConfigureInfo]
    cmd_template = "$CLI $CMD $DEFAULT_OPTIONS {OPTIONS}"
    transitive_files=(properties.toolchain_info_file_list + properties.jq_info_file_list)
    runfiles=[configure_info.config_file_info]
    cmd=[]

    variables = [
        'CLI="%s"' % properties.cli,
        'JQ_TOOL="%s"' % properties.jq_tool,
        'DEFAULT_OPTIONS="--profile %s %s"'% (configure_info.profile, configure_info.debug),
        'CMD="%s %s"' % (ctx.attr._api,api_cmd),
        'CLUSTER_NAME="%s"' % configure_info.cluster_name,
        'CONFIG_FILE_INFO=$(cat %s)' % configure_info.config_file_info.short_path
    ]

    if api_cmd in ["install", "uninstall"]:
        if ctx.attr.dbfs:
            dbfs = ctx.attr.dbfs
            transitive_files.append(dbfs[DefaultInfo].files_to_run.executable)
            transitive_files+=(dbfs[FsInfo].files.to_list())

        if dbfs[FsInfo].stamp_file:
            transitive_files.append(dbfs[FsInfo].stamp_file)
            variables+=['STAMP=$(cat %s)' % dbfs[FsInfo].stamp_file.short_path]

            if api_cmd == "install":
                cmd+=["exe '%s'" % dbfs[DefaultInfo].files_to_run.executable.short_path]

            cmd+=[cmd_template.format(OPTIONS = "--jar %s" % f) for f in dbfs[FsInfo].dbfs_files_path]

        if ctx.attr.maven_info:
            cmd+=[
                ' && '.join(
                    [cmd_template.format(
                            OPTIONS = '--maven-repo %s --maven-coordinates %s' % (r,c)
                        ) for c in cs]
                    ) for (r, cs) in ctx.attr.maven_info.items()
                ]

    if api_cmd == "cluster-status":
        cmd+=[
            "CLUSTER_STATUS=$(%s)" % cmd_template.format(OPTIONS = ""),
        ] + ["echo $CLUSTER_STATUS | $JQ_TOOL ."]

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


_libraries_status = rule(
    implementation = _impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
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
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "install")
        },
    ),
)

_libraries_uninstall = rule(
    implementation = _impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "uninstall")
        },
    ),
)


def libraries (name, **kwargs):
    _libraries_status(name = name, **kwargs)
    _libraries_status(name = name + ".status", **kwargs)
    _libraries_install(name = name + ".install",**kwargs)
    _libraries_uninstall(name = name + ".uninstall",**kwargs)
