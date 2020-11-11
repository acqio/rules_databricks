load("//databricks/private/common:common.bzl", "DATABRICKS_TOOLCHAIN")
load("//databricks/private/common:utils.bzl", "utils")
load("//databricks/private:providers/providers.bzl", "ConfigureInfo")

def _impl(ctx):
    files = []

    profile = ctx.attr.profile or ""
    if not profile:
        fail("The profile value is mandatory.")
    if utils.check_stamping_format(profile):
        profile_file = ctx.actions.declare_file(ctx.label.name + ".profile")
        utils.resolve_stamp(ctx, profile, profile_file)
        profile = "$(cat %s)" % profile_file.short_path
        files.append(profile_file)

    return [
        ConfigureInfo(
            config_file = ctx.toolchains[DATABRICKS_TOOLCHAIN].info.config_file,
            profile = profile,
        ),
        DefaultInfo(
            runfiles = ctx.runfiles(
                files = files,
            ),
        ),
    ]

configure = rule(
    implementation = _impl,
    toolchains = [DATABRICKS_TOOLCHAIN],
    attrs = {
        "_stamper": attr.label(
            default = Label("//databricks/private/cmd/stamper:stamper"),
            executable = True,
            cfg = "host",
        ),
        "profile": attr.string(
            default = "DEFAULT",
            mandatory = True,
        ),
    },
)

def _impl_alias(repository_ctx):
    repository_ctx.file(
        "BUILD.bazel",
        content = """
load("@rules_databricks//databricks:defs.blz", "dbk_configure")

databricks_configure(
    name = "configure",
    profile = "{profile}",
    visibility = ["//visibility:public"],
)
""".format(
            profile = repository_ctx.attr.profile,
        ),
    )

configure_alias = repository_rule(
    implementation = _impl_alias,
    attrs = {
        "profile": attr.string(default = "DEFAULT", mandatory = True),
    },
)
