<a name="databricks_configure"></a>
## databricks_configure

```python
databricks_configure(name, profile, cluster_name)
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
      <td><code>profile</code></td>
      <td>
        <code>String, required</code>
        <p>The name of the profile defined when set up authentication with databricks.</p>
        <p>This value is defined when <a href="/README.md#databricks_authentication">Set Up Authentication.</a></p>
        <p><code>profile = "DEFAULT"</code></p>
      </td>
    </tr>
    <tr>
      <td><code>cluster_name</code></td>
      <td>
        <code>String, required</code>
        <p>The name of the databricks cluster where operations can be performed.</p>
        <p><code>cluster_name = "FOO"</code></p>
      </td>
    </tr>
    <tr>
      <td><code>debug</code></td>
      <td>
        <code>Boolean, optional</code>
        <p>Shows full stack trace on error</p>
        <p><code>debug = True</code></p>
      </td>
    </tr>
  </tbody>
</table>
