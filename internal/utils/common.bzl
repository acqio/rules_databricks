DBFS_PROPERTIES = {
    "dbfs_path_jars": "dbfs:/FileStore/jars",
    "dbfs_path_maven": "dbfs:/FileStore/maven",
    "dbfs_filepath_prefix": "bazel"
}

DATABRICKS_API_COMMAND_ALLOWED = {
    "fs": ["cp", "rm", "ls"]
}

MAVEN_REPO = [
    "https://repo.maven.apache.org/maven2/",
    "https://maven.databricks.com"
]

CMD_CONFIG_FILE_STATUS = """
# if [ $(echo $CONFIG_FILE_INFO | ${JQ_TOOL} -r .status) == "error" ] ; then
#     echo "FAIL: Databricks Configuration file"
#     echo "OUTPUT:" $(echo $CONFIG_FILE_INFO | ${JQ_TOOL} -r .message)
#     exit 1
# fi
"""

CMD_CLUSTER_INFO = """
echo ${CLUSTER_ID}

# if [ "${CLUSTER_ID}" == "" ] ; then
#     echo "FAIL: Databricks cluster info"
#     echo "OUTPUT:" $(echo $CLUSTER_ID | ${JQ_TOOL} -r .message)
#     exit 1
# fi


"""
