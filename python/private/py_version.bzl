load("//python/private:providers.bzl", "PyVersionInfo")

DEFAULT_PYTHON_VERSION_SENTINAL = "__DEFAULT_PYTHON_VERSION_SENTINAL__"
DEFAULT_PYTHON_VERSION_SENTINAL_LABEL = "//python/private:" + DEFAULT_PYTHON_VERSION_SENTINAL

def _py_version_impl(ctx):
    version = ctx.attr.version
    return [
        PyVersionInfo(
            version = version,
        ),
    ]

py_version = rule(
    implementation = _py_version_impl,
    attrs = {
        "version": attr.string(
            mandatory = True,
        ),
    },
    provides = [PyVersionInfo],
)

def py_version_default(name = DEFAULT_PYTHON_VERSION_SENTINAL, **kwargs):
    py_version(
        name = name,
        version = DEFAULT_PYTHON_VERSION_SENTINAL,
        visibility = ["//visibility:public"],
        **kwargs
    )
