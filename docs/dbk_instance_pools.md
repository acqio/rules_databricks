<a name="dbk_instance_pools"></a>
## dbk_instance_pools

```python
dbk_instance_pools(name, configure, template, substitutions)
```

For example, if the BUILD file contains:

```python

dbk_instance_pools(
  name = "pools"
  configure = ":cfg",
  template = ":example.json",
  substitutions = {},
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
      <td><code>configure</code></td>
      <td>
        <code>Label, required</code>
        <p>Label of <code>dbk_configure</code> target.</p>
        <p>Specify the databricks cluster settings.</p>
        <p><code>configure = ":cfg"</code></p>
      </td>
    </tr>
    <tr>
      <td><code>template</code></td>
      <td>
        <code>json file; required</code>
        <p>File containing JSON request to POST to /api/2.0/cluster-pools/create</p>
      </td>
    </tr>
        <tr>
    <td><code>substitutions</code></td>
      <td>
        <p><code>string_dict, optional</code></p>
        <p>Substitutions to make when expanding the template.</p>
      </td>
    </tr>
    <tr>
  </tbody>
</table>

## Usage

The `dbk_instance_pools` rules expose a collection of actions. We will follow the `:pools`
target from the example above.

### Resolve

You can "resolve" your `template` by running:
```shell
bazel run :pools.resolve
```

The resolved `template` will be printed to `STDOUT`.

### Get

Users can get the instance pool configuration by running

```shell
bazel run :pools.get
```
The result will be printed to `STDOUT`.

### Create or Edit

Users can create or edit the instance pool configuration by running:
```shell
bazel run :pools.create
```

### Delete

Users can delete the instance pool configuration by running:
```shell
bazel run :pools.delete
```
