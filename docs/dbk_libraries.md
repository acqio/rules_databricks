<a name="dbk_libraries"></a>
## dbk_libraries

```python
dbk_libraries(name, cluster_name, configure, dbfs, maven_info, maven_package_exclusion)
```

For example, if the BUILD file contains:

```python

dbk_libraries(
    name = "lib"
    cluster_name = "test",
    configure = ":cfg",
    dbfs = ":src.cp",
    maven_info = {
        "https://repo.maven.apache.org/maven2/" : [
          "GroupId:ArtifactId:Version"
        ]
    },
    maven_package_exclusion = {
        "GroupId:ArtifactId:Version" : [
          "foo:bar"
        ]
    },
)
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
      <td><code>cluster_name</code></td>
      <td>
        <code>String, required</code>
        <p>The name of the databricks cluster where operations can be performed.</p>
        <p><code>cluster_name = "FOO"</code></p>
        <p>This field supports stamp variables.</p>
      </td>
    </tr>
    <tr>
      <td><code>configure</code></td>
      <td>
        <code>Label, required</code>
        <p>Label of <code>dbk_configure</code> target.</p>
        <p>Specify the databricks cluster settings.</p>
        <p><code>configure = ":cfg"</code></p>
      </td>
    </tr>
    <tr>
      <td><code>dbfs</code></td>
      <td>
        <code>Label, optional</code>
        <p>File to add to the Databricks File Store (DBFS).</p>
        <p>The file path in DBFS follows the pattern: <code>dbfs:/FileStore/bazel/{target}</code></p>
      </td>
    </tr>
    <tr>
      <td><code>maven_info</code></td>
      <td>
        <code>String list Dict, optional</code>
        <p>
          The keys are the URLs of the maven repository and
          the list is coordinated by the maven in the form of GroupId:ArtifactId:Version
        </p>
        <p>
          <code>maven_info = { "https://repo.maven.apache.org/maven2/": ["GroupId:ArtifactId:Version"] }</code>
        </p>
      </td>
    </tr>
    <tr>
      <td><code>maven_package_exclusion</code></td>
      <td>
        <code>String list Dict, optional</code>
        <p>
          The keys are the GroupId:ArtifactId:Version coordinated of the maven and
          the list with the dependencies to be excluded.
        </p>
        <p>
          <code>maven_info = { "GroupId:ArtifactId:Version": ["foo:bar"] }</code>
        </p>
      </td>
    </tr>
  </tbody>
</table>

## Usage

The `dbk_libraries` rules expose a collection of actions. We will follow the `:lib`
target from the example above.

### Status

Users can list the state of the libraries in the cluster by running:
```shell
bazel run :lib
```

### Install

Users can install libraries by running:
```shell
bazel run :lib.install
```

### Uninstall

Users can uninstall libraries by running:
```shell
bazel run :lib.uninstall
```

It is notable that when uninstalling a library, a message to restart the cluster is displayed.
This action must be performed manually by the Databricks administrator.
