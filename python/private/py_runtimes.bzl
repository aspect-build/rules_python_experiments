"""Python Runtimes Rule"""

load("//python/private:providers.bzl", "PyInterpreterInfo", "PyVersionInfo")
load("//python/private:py_version.bzl", "DEFAULT_PYTHON_VERSION_SENTINAL")

def _py_runtimes_impl(ctx):
    interpreters = {}
    default_version = ctx.attr.default_version
    default_version_info = None

    for interpreter in ctx.attr.interpreters:
        info = interpreter[PyInterpreterInfo]
        version_info = info.version[PyVersionInfo]
        interpreters[version_info.version] = info

        if version_info.version == default_version[PyVersionInfo].version:
            interpreters[DEFAULT_PYTHON_VERSION_SENTINAL] = info
            default_version_info = info

    if default_version_info == None:
        fail("No matching interpreter version found for given default")

    return [
        platform_common.ToolchainInfo(
            interpreters = interpreters,
            default_version_info = default_version_info,
        ),
    ]

py_runtimes = rule(
    implementation = _py_runtimes_impl,
    attrs = {
        "default_version": attr.label(
            mandatory = True,
            providers = [PyVersionInfo],
        ),
        "interpreters": attr.label_list(
            mandatory = True,
            providers = [PyInterpreterInfo],
        ),
    },
    doc = "",
)
