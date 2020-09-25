DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

DBFS_PROPERTIES = {
    "dbfs_basepath": "dbfs:/FileStore",
    "dbfs_prefix_filepath": "bazel/",
}

CHECK_CONFIG_FILE = """
$READER_CONFIG_FILE $DEFAULT_OPTIONS --config_file $DATABRICKS_CONFIG_FILE
"""

CMD_CLUSTER_INFO = """
CLUSTER_ID=$($CLI clusters get $DEFAULT_OPTIONS --cluster-name $CLUSTER_NAME | $JQ_TOOL -r .cluster_id)

if [ "$CLUSTER_ID" == "" ] ; then
    echo "FAIL: Databricks cluster info"
    echo "OUTPUT:" $(echo $CLUSTER_ID | $JQ_TOOL -r .message)
    exit 1
fi

DEFAULT_OPTIONS="${DEFAULT_OPTIONS} --cluster-id $CLUSTER_ID"
"""
