# Databricks Rules for Bazel

## Overview

This repository contains rules for interacting with Databricks configurations/clusters.

## Requirements

* Python Version > 3.6

## Setup

Add the following to your `WORKSPACE` file to add the necessary external dependencies:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# This requires that python be available in your distribution,
# as this project uses rules_python to build the binary databricks cli.

http_archive(
    name = "rules_databricks",
    urls = [
        "https://github.com/acqio/rules_databricks/archive/v0.5.tar.gz"
    ],
    sha256 = "b21301eb81b41162ae612ff708b8466ab94db55b111605a492708d03d74e532c",
    strip_prefix = "rules_databricks-0.5",
)

load("@rules_databricks//databricks:repositories.bzl", databricks_repositories = "repositories")

databricks_repositories()

load("@rules_databricks//databricks:deps.bzl", databricks_deps = "deps")

databricks_deps()

load("@rules_databricks//databricks:pip_repositories.bzl", databricks_pip_deps = "pip_deps")

databricks_pip_deps()

register_toolchains("@rules_databricks//toolchain/databricks:default_linux_toolchain")
```

Add the flag `--build_python_zip` following to your `.bazelrc` to create a python executable zip:

```
run --build_python_zip
```

## Simple usage

The rules_databricks target can be used as executables for custom actions or can be executed directly by Bazel. For example, you can run:

```sh
bazel run @rules_databricks//:cli -- -h
```

## Set up Authentication
<a name="databricks_authentication"></a>

Then set up authentication using username/password or [authentication token](https://docs.databricks.com/api/latest/authentication.html#token-management). Credentials are stored at ``~/.databrickscfg``.

- `bazel run @rules_databricks//:cli -- configure --token` (enter hostname/auth-token at prompt)

Multiple connection profiles are also supported with `bazel run @rules_databricks//:cli -- configure --profile <profile> [--token]`.
The connection profile can be used as such: `bazel run @rules_databricks//:cli -- workspace ls --profile <profile>`.

To test that your authentication information is working, try a quick test like `bazel run @rules_databricks//:cli -- workspace ls`.

## Rules

* [databricks_configure](docs/databricks_configure.md)
* [databricks_fs](docs/databricks_fs.md)
* [databricks_libraries](docs/databricks_libraries.md)
