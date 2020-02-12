load("//internal/utils:utils.bzl", "utils", "dirname", "join_path")
load("//internal/utility:configure.bzl", "configure")
load("//internal/utils:providers.bzl", "FsInfo", "ConfigureInfo")
load("//internal/utils:common.bzl", "DBFS_PROPERTIES", "DATABRICKS_API_COMMAND_ALLOWED")
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

def _aspect_srcs(ctx):

    dbfs_dest = join_path(DBFS_PROPERTIES["dbfs_path_jars"], DBFS_PROPERTIES["dbfs_filepath_prefix"])
    dictionary = []
    for src in ctx.files.srcs:
        dictionary.append(dict({
                "bazel_srcs": src,
                "dbfs_srcs_path": (dbfs_dest + src.path),
                "dbfs_srcs_dirname": (dbfs_dest + src.dirname)
            })
        )

    return dictionary


_common_attr  = {
    "_script_tpl": attr.label(
        default = Label("//internal/utility:fs.sh.tpl"),
        allow_single_file = True,
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
}

def _common_properties(ctx):

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

def _common_impl(ctx):
    properties = _common_properties(ctx)
    aspects = _aspect_srcs(ctx)
    api = ctx.attr._api
    cmd=[]

    if not ctx.attr._command in "ls":
        cmd = [
            "${CLI} ${CLI_COMMAND} --overwrite --debug %s %s" % (
                aspect["bazel_srcs"].path , aspect["dbfs_srcs_path"])
            for aspect in aspects
        ]

    cmd.append("${CLI} %s ls --absolute -l %s" % (api, aspects[0]["dbfs_srcs_dirname"]))
    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._script_tpl,
        substitutions = {
            "%{CLI}": properties.cli,
            "%{PROFILE}": properties.profile,
            "%{CLUSTER_NAME}": properties.cluster_name,
            "%{CLI_COMMAND}": "%s %s" % (api, ctx.attr._command),
            "%{CMD}": '; \n#'.join(cmd)
        }
    )

    return [
            DefaultInfo(
                runfiles = ctx.runfiles(
                    files = properties.toolchain_info_file_list + properties.jq_info_file_list + ctx.files.srcs
                ),
            ),
            FsInfo(
                srcs = [aspect["bazel_srcs"] for aspect in aspects],
                dbfs_file_path = [aspect["dbfs_srcs_path"] for aspect in aspects],
            )
        ]


_fs_cp = rule(
    implementation = _common_impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = utils.add_dicts(
        _common_attr,
        {
            "_command": attr.string(default = "cp")
        },
    ),
)

_fs_ls = rule(
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    implementation = _common_impl,
    attrs = utils.add_dicts(
        _common_attr,
        {
            "_command": attr.string(default = "ls")
        },
    ),
)

def fs(name, **kwargs):

    if "directory" in kwargs:
        if not kwargs["directory"].strip():
            fail ("The directory attribute cannot be an empty string.")

    _fs_ls(name = name, **kwargs)
    _fs_ls(name = name + ".ls", **kwargs)

    _fs_cp(name = name + ".cp",**kwargs)
