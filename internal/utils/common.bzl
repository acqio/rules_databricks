DBFS_PROPERTIES = {
    "dbfs_path_jars": "dbfs:/FileStore/jars",
    "dbfs_path_maven": "dbfs:/FileStore/maven",
    "dbfs_filepath_prefix": "bazel"
}

DATABRICKS_API_COMMAND_ALLOWED = {
    "fs": ["cp", "rm", "ls"]
}
