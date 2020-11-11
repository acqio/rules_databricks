ConfigureInfo = provider(
    fields = [
        "profile",
        "config_file",
    ],
)

FsInfo = provider(
    doc = "",
    fields = [
        "dbfs_files_path",
        "files",
        "stamp_file",
    ],
)
