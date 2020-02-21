FsInfo = provider(
    doc = "",
    fields = {
        "srcs": "",
        "dbfs_srcs_path": "List with path in dbfs of uploaded files",
        "stamp_file":"",
    },
)

ConfigureInfo = provider(
    fields = {
        "profile" : 'The profile defined in the databricks configure',
        "cluster_name": "The name of the cluster that the rules will interact with.",
        "config_file_info": ""
    }
)
