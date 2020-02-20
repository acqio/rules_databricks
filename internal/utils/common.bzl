DBFS_PROPERTIES = {
    "dbfs_jars_basepath": "dbfs:/FileStore/jars",
    "dbfs_maven_basepath": "dbfs:/FileStore/maven",
    "dbfs_prefix_filepath": "bazel"
}

DATABRICKS_API_COMMAND_ALLOWED = {
    "fs": ["cp", "rm", "ls"]
}

MAVEN_REPO = [
    "https://repo.maven.apache.org/maven2/",
    "https://maven.databricks.com"
]

CMD_CONFIG_FILE_STATUS = """
if [ $(echo ${CONFIG_FILE_INFO} | ${JQ_TOOL} -r .status) == "error" ] ; then
    echo "FAIL: Databricks Configuration file"
    echo "OUTPUT:" $(echo ${CONFIG_FILE_INFO} | ${JQ_TOOL} -r .message)
    exit 1
fi
"""

CMD_CLUSTER_INFO = """
if [ "${CLUSTER_ID}" == "" ] ; then
    echo "FAIL: Databricks cluster info"
    echo "OUTPUT:" $(echo $CLUSTER_ID | ${JQ_TOOL} -r .message)
    exit 1
fi
"""
