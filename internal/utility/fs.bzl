load("//internal/utils:utils.bzl", "utils", "dirname", "join")
load(
    "//internal/utility:providers.bzl", "FsCopyInfo",
)
_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

_common_attr  = {
    "_fs_script_tpl": attr.label(
        default = Label("//internal/utility:fs.sh.tpl"),
        allow_single_file = True,
    )
}

def _impl(ctx):
    toolchain_info = ctx.toolchains[_DATABRICKS_TOOLCHAIN].info
    print(toolchain_info)
    profile = ctx.toolchains[_DATABRICKS_TOOLCHAIN].info.profile
    python_interpreter = toolchain_info.tool_target[PyRuntimeInfo].interpreter
    program = toolchain_info.tool_target[DefaultInfo].files_to_run.executable.short_path

    runfiles = utils.runfiles(
        ctx,
        utils.runfiles(ctx, toolchain_info.tool_target[DefaultInfo].default_runfiles, ctx.files.srcs),
        [python_interpreter]
    )
    cmd=[]
    FsCopyInfo_dbfs_dest_files=[]


    args = ctx.actions.args
    src_path_prefix = "bazel/"

    for (label, value) in ctx.attr.srcs.items():
        dbfs_dest = value
        src_dirname=""
        for src in label.files.to_list():
            src_dirname = src.dirname
            src_dbfs_dest = dbfs_dest + src_path_prefix + src.path
            FsCopyInfo_dbfs_dest_files.append(src_dbfs_dest)
            cmd.append(
                ' '.join([
                        "${PYTHON_WRAPPER}",
                        "${DATABRICK_CLI_PATH}",
                        "fs cp",
                        "${DATABRICK_CLI_OPTIONS}",
                        "--overwrite",
                        src.path,
                        src_dbfs_dest
                    ])
            )

        src_dirname_dbfs_dest = dbfs_dest + src_path_prefix + src_dirname
        # print (src_dirname_dbfs_dest)
        cmd.append(
            ' '.join([
                    "${PYTHON_WRAPPER}",
                    "${DATABRICK_CLI_PATH}",
                    "fs ls",
                    "${DATABRICK_CLI_OPTIONS}",
                    "--absolute -l",
                    src_dirname_dbfs_dest
                ])
        )

    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._fs_script_tpl,
        substitutions = {
            "%{PYTHON_WRAPPER}": python_interpreter.short_path,
            "%{DATABRICK_CLI_PATH}": program,
            "%{DATABRICK_CLI_OPTIONS}": "--profile %s" % profile,
            "%{CMD}": '; \n#'.join(cmd)
        }
    )

    return [
            DefaultInfo(
                runfiles = runfiles,
                files = depset([ctx.outputs.executable]),
            ),
            FsCopyInfo(
                srcs = ctx.files.srcs,
                dbfs_file_path = FsCopyInfo_dbfs_dest_files,
            )
        ]


fs_copy = rule(
    implementation = _impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN,],
    attrs = utils.add_dicts(
        _common_attr,
        {
            "srcs": attr.label_keyed_string_dict(
                mandatory = True,
                allow_files = True,
                # allow_files = [".jar"],
                allow_empty = False
            ),
        },
    ),
)
