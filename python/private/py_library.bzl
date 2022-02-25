load("@bazel_skylib//lib:paths.bzl", "paths")
load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("//python/private:providers.bzl", "PyWheelInfo")

def _make_import_path(workspace, base, imp):
    if imp.startswith(".."):
        return paths.normalize(paths.join(workspace, *base.split("/")[0:-len(imp.split("/"))]))
    else:
        return paths.normalize(paths.join(workspace, base, imp))

def _py_library_impl(ctx):
    transitive_srcs = depset(
        order = "postorder",
        direct = ctx.files.srcs,
        transitive = [
            target[PyInfo].transitive_sources
            for target in ctx.attr.deps
            if PyInfo in target
        ],
    )

    transitive_wheels = depset(
        direct = ctx.files.wheels,
        transitive = [
            target[PyWheelInfo].transitive_srcs
            for target in ctx.attr.deps
            if PyWheelInfo in target
        ],
    )

    base = paths.dirname(ctx.build_file_path)
    import_paths = [
        _make_import_path(ctx.workspace_name, base, im)
        for im in ctx.attr.imports
    ]

    imports = depset(
        direct = import_paths,
        transitive = [
            target[PyInfo].imports
            for target in ctx.attr.deps
            if PyInfo in target
        ],
    )

    runfiles_targets = ctx.attr.deps + ctx.attr.data
    runfiles = ctx.runfiles(files = ctx.files.data)
    runfiles = runfiles.merge_all([
        target[DefaultInfo].default_runfiles
        for target in runfiles_targets
    ])

    return [
        DefaultInfo(
            files = depset(direct = ctx.files.srcs, transitive = [transitive_srcs]),
            default_runfiles = runfiles,
        ),
        PyWheelInfo(
            srcs = depset(direct = ctx.files.wheels),
            transitive_srcs = depset(direct = ctx.files.wheels, transitive = [transitive_wheels]),
        ),
        PyInfo(
            imports = imports,
            transitive_sources = transitive_srcs,
            has_py2_only_sources = False,
            has_py3_only_sources = True,
            uses_shared_libraries = False,
        ),
    ]

_py_library = rule(
    implementation = _py_library_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "deps": attr.label_list(
            allow_files = True,
            providers = [[PyInfo], []],
        ),
        "data": attr.label_list(
            allow_files = True,
        ),
        "wheels": attr.label_list(
            allow_files = True,
            providers = [
                # PyWheelInfo,
            ],
        ),
        "imports": attr.string_list(),
        "root": attr.string(),
    },
    provides = [
        DefaultInfo,
        PyWheelInfo,
        PyInfo,
    ],
)

def py_library(name, **kwargs):
    _py_library(
        name = name,
        **kwargs
    )
