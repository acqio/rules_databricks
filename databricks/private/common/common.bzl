DATABRICKS_TOOLCHAIN = "@rules_databricks//databricks/toolchain:toolchain_type"

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

CMD_INSTANCE_POOL_INFO = """
INSTANCE_POOL_NAME=$(${JQ_TOOL} -r .instance_pool_name <<< ${INSTANCE_POOL_JSONFILE_TEMPLATE})
INSTANCE_POOL_INFO=$(\
${JQ_TOOL} -r \'(.instance_pools[] | select (.instance_pool_name=="\'${INSTANCE_POOL_NAME}\'" | .))\' \
<<< $(${CLI} instance-pools list ${DEFAULT_OPTIONS} --output JSON))
"""

CMD_INSTANCE_POOL_ID = """
INSTANCE_POOL_ID=$(${JQ_TOOL} -r .instance_pool_id <<< ${INSTANCE_POOL_INFO})
"""
