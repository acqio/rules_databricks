# Databricks Rules for Bazel

## Overview

[Bazel](https://bazel.build/) is a tool for building and testing software and can handle large,
multi-language projects at scale.

This project defines the main rules for interaction with databricks Clusters, through the [Databricks CLI](https://docs.databricks.com/dev-tools/cli/) project.

## Rules

* [dbk_fs](docs/scala_library.md)
* [dbk_library](docs/scala_macro_library.md)

## Requirements

* Python Version > 2.7.9 or > 3.6

## Setup

Add the following to your `WORKSPACE` file to add the necessary external dependencies:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# This requires that python be available in your distribution,
# as this project uses rules_python to build the binary databricks cli.
# Download the rules_databricks repository at release v0.1

http_archive(
    name = "rules_databricks",
    sha256 = "cc75cf0d86312e1327d226e980efd3599704e01099b58b3c2fc4efe5e321fcd9",
    strip_prefix = "rules_databricks-0.1",
    urls = [
        "https://github.com/bazelbuild/rules_databricks/releases/download/v0.1/rules_databricks-v0.1.tar.gz"
    ],
)

load("@rules_databricks//databricks:deps.bzl", "repositories")
repositories()

load("@rules_databricks//databricks:py_deps.bzl", py_deps = "deps")
py_deps()

load("@rules_databricks//databricks:py_pip_deps.bzl", py_pip_deps = "deps")
py_pip_deps()
```

## Authentication in Databricks Cluster

Then set up authentication using username/password or `authentication token <https://docs.databricks.com/api/latest/authentication.html#token-management>`_. Credentials are stored at ``~/.databrickscfg``.

- ``bazel run @rules_databricks//:cli -- configure`` (enter hostname/username/password at prompt)
- ``bazel run @rules_databricks//:cli -- configure --token`` (enter hostname/auth-token at prompt)

Multiple connection profiles are also supported with ``bazel run @rules_databricks//:cli -- configure --profile <profile> [--token]``.
The connection profile can be used as such: ``bazel run @rules_databricks//:cli -- workspace ls --profile <profile>``.

To test that your authentication information is working, try a quick test like ``bazel run @rules_databricks//:cli -- workspace ls``.