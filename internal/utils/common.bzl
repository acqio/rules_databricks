DBFS_PROPERTIES = {
    "dbfs_srcs_basepath": "dbfs:/FileStore/jars",
    "dbfs_maven_basepath": "dbfs:/FileStore/maven",
    "dbfs_prefix_filepath": "bazel"
}

DATABRICKS_API_COMMAND_ALLOWED = {
    "fs": ["cp", "rm", "ls"]
}

CMD_CONFIG_FILE_STATUS = """
if [ $(echo $CONFIG_FILE_INFO | $JQ_TOOL -r .status) == "error" ] ; then
    echo "FAIL: Databricks Configuration file"
    echo "OUTPUT:" $(echo $CONFIG_FILE_INFO | $JQ_TOOL -r .message)
    exit 1
fi
"""
# cat cluster_libraries.json | $JQ_TOOL -r \'(.library_statuses[].library | select ( has("maven"))) | .maven.coordinates\'
CMD_CLUSTER_INFO = """
CLUSTER_ID=$($CLI clusters list $DEFAULT_ARGS --output JSON | \
$JQ_TOOL -r \'(.clusters[] | select (.cluster_name=="\'$CLUSTER_NAME\'")).cluster_id\')

if [ "$CLUSTER_ID" == "" ] ; then
    echo "FAIL: Databricks cluster info"
    echo "OUTPUT:" $(echo $CLUSTER_ID | $JQ_TOOL -r .message)
    exit 1
fi
"""
