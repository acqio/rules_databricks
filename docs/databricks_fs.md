<a name="databricks_fs"></a>
## databricks_fs

For example, if the BUILD file contains:

```python

databricks_fs(
  name = "src"
  configure = ":cfg",
  files = [":src.jar"],
  stamp = "{BUILD_TIMESTAMP}",
)
```

```python
databricks_fs(name, configure, files, stamp)
```

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <code>Name, required</code>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>configure</code></td>
      <td>
        <code>Label, required</code>
        <p>Label of `databricks_configure` target.</p>
        <p>Specify the databricks cluster settings.</p>
        <p><code>configure = ":cfg"</code></p>
      </td>
    </tr>
    <tr>
      <td><code>files</code></td>
      <td>
        <code>Label List of files, required</code>
        <p>File to add to the Databricks File Store (DBFS).</p>
        <p>The file path in DBFS follows the pattern: <code>dbfs:/FileStore/bazel/{target}</code></p>
      </td>
    </tr>
    <tr>
      <td><code>stamp</code></td>
      <td>
        <code>String, optional, default is empty string</code>
        <p>The name of the databricks cluster where operations can be performed.</p>
        <p>The values of this field support stamp variables.</p>
        <p><code>cluster_name = "{BUILD_TIMESTAMP}"</code></p>
      </td>
    </tr>
  </tbody>
</table>

## Usage

The `databricks_fs` rules expose a collection of actions. We will follow the `:src`
target from the example above.

### List

Users can list properties of files in DBFS by running:
```shell
bazel run :src
```

### Copy

Users can copy files to DBFS by running:
```shell
bazel run :src.cp
```

### Remove

Users can remove files from the DBFS by running:
```shell
bazel run :src.rm
```

It is notable that, despite deleting a file, it can be used in the cluster.
Therefore, make sure it is not in use before performing this action.
