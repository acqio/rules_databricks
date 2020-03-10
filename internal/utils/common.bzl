DBFS_PROPERTIES = {
    "dbfs_basepath": "dbfs:/FileStore",
    "dbfs_prefix_filepath": "bazel/"
}

CMD_CONFIG_FILE_STATUS = """
if [ $(echo $CONFIG_FILE_INFO | $JQ_TOOL -r .status) != "success" ] ; then
    echo "FAIL: Databricks Configuration file"
    echo "OUTPUT:" $(echo $CONFIG_FILE_INFO | $JQ_TOOL -r .message)
    exit 1
fi
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
