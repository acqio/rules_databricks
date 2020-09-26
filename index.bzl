load("//databricks:defs.bzl", "dbk_configure", "dbk_fs", "dbk_libraries")

def databricks_configure(**kwargs):
    print("""
Update the databricks_configure rule reference.
From:
load("@rules_databricks//:index.bzl", "databricks_configure")

To:
load("@rules_databricks//databricks:defs.blz", "dbk_configure")
""")
    dbk_configure(**kwargs)

def databricks_fs(**kwargs):
    print("""
Update the databricks_fs rule reference.
From:
load("@rules_databricks//:index.bzl", "databricks_fs")

To:
load("@rules_databricks//databricks:defs.blz", "dbk_fs")
""")
    dbk_fs(**kwargs)

def databricks_libraries(**kwargs):
    print("""
Update the databricks_libraries rule reference.
From:
load("@rules_databricks//:index.bzl", "databricks_libraries")

To:
load("@rules_databricks//databricks:defs.blz", "dbk_libraries")
""")
    dbk_libraries(**kwargs)
