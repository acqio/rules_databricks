load(
    "//databricks/private/common:common.bzl",
    "CHECK_CONFIG_FILE",
    "CMD_INSTANCE_POOL_ID",
    "CMD_INSTANCE_POOL_INFO",
    "DATABRICKS_TOOLCHAIN",
)
load("//databricks/private/common:utils.bzl", "utils")
load("//databricks/private:providers/providers.bzl", "ConfigureInfo")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

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

    variables = [
        'CLI="%s"' % properties.cli,
        'CMD="%s %s $@"' % (ctx.attr._api, api_cmd),
        'export DATABRICKS_CONFIG_FILE="%s"' % configure_info.config_file,
        'DEFAULT_OPTIONS="--profile %s"' % configure_info.profile,
        'JQ_TOOL="%s"' % properties.jq_tool,
        'READER_CONFIG_FILE="%s"' % reader_config_file,
    ]

    substitutions_file = ctx.actions.declare_file(ctx.label.name + ".substitutions.json")

    ctx.actions.expand_template(
        template = ctx.file.json_file,
        output = substitutions_file,
        substitutions = ctx.attr.substitutions,
    )

    runfiles += [substitutions_file]

    variables += [
        "INSTANCE_POOL_JSONFILE_TEMPLATE=$(cat %s)" % substitutions_file.short_path,
    ]

    substitutions_contitions = CHECK_CONFIG_FILE
    if api_cmd in ["create", "edit"]:
        cmd.append("${CLI} ${CMD} ${DEFAULT_OPTIONS} --json-file %s" % (substitutions_file.short_path))
    elif api_cmd in ["get"]:
        substitutions_contitions += CMD_INSTANCE_POOL_INFO
        cmd.append("${JQ_TOOL} -M . <<< ${INSTANCE_POOL_INFO}")
    elif api_cmd in ["delete"]:
        substitutions_contitions += (CMD_INSTANCE_POOL_INFO + CMD_INSTANCE_POOL_ID)
        cmd.append("${CLI} ${CMD} ${DEFAULT_OPTIONS} --instance-pool-id ${INSTANCE_POOL_ID}")
    else:
        cmd.append('${JQ_TOOL} -M . "%s"' % substitutions_file.short_path)

    ctx.actions.expand_template(
        is_executable = True,
        output = ctx.outputs.executable,
        template = ctx.file._resolve_tpl,
        substitutions = {
            "%{VARIABLES}": "\n".join(variables),
            "%{CONDITIONS}": substitutions_contitions,
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
    ]

_common_attr = {
    "_resolve_tpl": attr.label(
        default = utils.resolve_tpl,
        allow_single_file = True,
    ),
    "_config_file_reader": attr.label(
        default = Label("//databricks/private/cmd/config_file_reader:main"),
        executable = True,
        cfg = "host",
    ),
    "_api": attr.string(
        default = "instance-pools",
    ),
    "configure": attr.label(
        mandatory = True,
        providers = [ConfigureInfo],
    ),
    "json_file": attr.label(
        mandatory = True,
        allow_single_file = [".json"],
    ),
    "substitutions": attr.string_dict(),
}

_instance_pools_resolve = rule(
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    implementation = _impl,
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "resolve"),
        },
    ),
)

_instance_pools_get = rule(
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    implementation = _impl,
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "get"),
        },
    ),
)

_instance_pools_create = rule(
    implementation = _impl,
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "create"),
        },
    ),
)

_instance_pools_edit = rule(
    implementation = _impl,
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "edit"),
        },
    ),
)

_instance_pools_delete = rule(
    implementation = _impl,
    executable = True,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = dicts.add(
        _common_attr,
        {
            "_command": attr.string(default = "delete"),
        },
    ),
)

def instance_pools(name, **kwargs):
    _instance_pools_resolve(name = name, **kwargs)
    _instance_pools_resolve(name = name + ".resolve", **kwargs)
    _instance_pools_get(name = name + ".get", **kwargs)
    _instance_pools_create(name = name + ".create", **kwargs)
    _instance_pools_edit(name = name + ".edit", **kwargs)
    _instance_pools_delete(name = name + ".delete", **kwargs)
