def _check_stamping_format(f):
    if f.startswith("{") and f.endswith("}"):
        return True
    return False

def _resolve_stamp(ctx, string, output):
    stamps = [ctx.info_file, ctx.version_file]
    args = ctx.actions.args()
    args.add_all(stamps, format_each = "--stamp-info-file=%s")
    args.add(string, format = "--format=%s")
    args.add(output, format = "--output=%s")
    ctx.actions.run(
        executable = ctx.executable._stamper,
        arguments = [args],
        inputs = stamps,
        tools = [ctx.executable._stamper],
        outputs = [output],
        mnemonic = "Stamp",
    )

def resolve_config_file(ctx, config_file, profile, output):
    args = ctx.actions.args()
    args.add(config_file, format = "--config_file=%s")
    args.add(profile, format = "--profile=%s")
    args.add(output, format = "--output=%s")
    ctx.actions.run(
        executable = ctx.executable._reading_from_file,
        arguments = [args],
        tools = [ctx.executable._reading_from_file],
        outputs = [output],
        mnemonic = "ProfileStatus",
    )

def _toolchain_properties(ctx, toolchain):
    toolchain_info = ctx.toolchains[toolchain].info
    jq_info = toolchain_info.jq_tool_target[DefaultInfo]

    return struct(
        toolchain_info = toolchain_info,
        toolchain_info_file_list = toolchain_info.tool_target.files.to_list(),
        cli = toolchain_info.tool_target[DefaultInfo].files_to_run.executable.short_path,
        config_file = toolchain_info.config_file,
        jq_info = jq_info,
        jq_tool = jq_info.files_to_run.executable.path,
        jq_info_file_list = jq_info.files.to_list(),
    )

helpers = struct(
    check_stamping_format = _check_stamping_format,
    resolve_stamp = _resolve_stamp,
    toolchain_properties = _toolchain_properties,
)
