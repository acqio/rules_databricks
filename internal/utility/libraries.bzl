load("//internal/utils:utils.bzl", "utils", "dirname", "join")
load("//internal/utility:providers.bzl", "FsCopyInfo",)

_DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchains/databricks:toolchain_type"

_implicit_deps  = dict(
    {
        "_lib_sh_tpl": attr.label(
          default = Label("//internal/utility:lib.sh.tpl"),
          allow_single_file = True,
        )
    }
)

def _impl(ctx):
    toolchain_info = ctx.toolchains[_DATABRICKS_TOOLCHAIN].info
    profile = ctx.toolchains[_DATABRICKS_TOOLCHAIN].info.profile
    python_interpreter = toolchain_info.tool_target[PyRuntimeInfo].interpreter
    databricks_cli = toolchain_info.tool_target[DefaultInfo].files_to_run.executable.short_path
    jq_info = toolchain_info.jq_tool_target[DefaultInfo]
    cluster_name = ctx.attr.cluster_name or ""

    if not cluster_name.strip():
        fail("deu merda")


    cmd = '; '.join([
        "echo '$PYTHON $CLI $CLI_OPTIONS $CLI_COMMAND --cluster-id $CLUSTER_ID --jar %s'" % dbfs_file
            for dbfs_file in ctx.attr.deps[FsCopyInfo].dbfs_file_path
        ])

    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._lib_sh_tpl,
        substitutions = {
            "%{PYTHON}": python_interpreter.short_path,
            "%{CLI}": databricks_cli,
            "%{CLI_OPTIONS}": "--profile %s" % profile,
            "%{CLUSTER_NAME}": cluster_name,
            "%{JQ_PATH}": jq_info.files_to_run.executable.path,
            "%{CLI_COMMAND}": "libraries install",
            "%{CMD}": "# " + cmd
        }
    )

    runfiles = ctx.runfiles(files = [python_interpreter] + jq_info.files.to_list())

    return [
            DefaultInfo(
                runfiles = runfiles.merge(toolchain_info.tool_target[DefaultInfo].default_runfiles),
                files = depset([ctx.outputs.executable]),
            ),
        ]

lib_install = rule(
    implementation = _impl,
    executable = True,
    toolchains = [_DATABRICKS_TOOLCHAIN],
    attrs = utils.add_dicts(
        _implicit_deps,
        {
            "deps": attr.label(
                mandatory = True,
                providers = [FsCopyInfo]
            ),
            "cluster_name": attr.string(
                mandatory = True
            ),
        },
    ),
)
