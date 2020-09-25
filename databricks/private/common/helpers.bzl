DBFS_PROPERTIES = {
    "dbfs_basepath": "dbfs:/FileStore",
    "dbfs_prefix_filepath": "bazel/",
}

CHECK_CONFIG_FILE = """
$READER_CONFIG_FILE $DEFAULT_OPTIONS --config_file $DATABRICKS_CONFIG_FILE
"""

CMD_CLUSTER_INFO = """
CLUSTER_ID=$($CLI clusters list $DEFAULT_OPTIONS --output JSON | \
$JQ_TOOL -r \'(.clusters[] | select (.cluster_name=="\'$CLUSTER_NAME\'")).cluster_id\')

if [ "$CLUSTER_ID" == "" ] ; then
    echo "FAIL: Databricks cluster info"
    echo "OUTPUT:" $(echo $CLUSTER_ID | $JQ_TOOL -r .message)
    exit 1
fi

DEFAULT_OPTIONS="${DEFAULT_OPTIONS} --cluster-id $CLUSTER_ID"
"""

def resolve_stamp(ctx, string, output):
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

def toolchain_properties(ctx, toolchain):
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
