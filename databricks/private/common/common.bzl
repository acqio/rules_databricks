DATABRICKS_TOOLCHAIN = "@rules_databricks//toolchain/databricks:toolchain_type"

DBFS_PROPERTIES = {
    "dbfs_basepath": "dbfs:/FileStore",
    "dbfs_prefix_filepath": "bazel/",
}

CHECK_CONFIG_FILE = """
$READER_CONFIG_FILE ${DEFAULT_OPTIONS} --config_file ${DATABRICKS_CONFIG_FILE}
"""

CMD_CLUSTER_INFO = """
set +e
CLUSTER_INFO=$(${CLI} clusters get ${DEFAULT_OPTIONS} --cluster-name ${CLUSTER_NAME})
set -e

if [[ $(echo $CLUSTER_INFO | grep -iF "erro") ]]; then
    echo "FAIL: Databricks cluster info"
    echo "OUTPUT: ${CLUSTER_INFO}"
    exit 1
fi

CLUSTER_ID=$(echo ${CLUSTER_INFO} | ${JQ_TOOL} -r .cluster_id)
DEFAULT_OPTIONS="${DEFAULT_OPTIONS} --cluster-id ${CLUSTER_ID}"
"""
