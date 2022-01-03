""

load("//python/private:providers.bzl", "PyVersionInfo")
load("//python/private:toolchain.bzl", "PYTHON_TOOLCHAIN")
load("//python/private:py_version.bzl", "DEFAULT_PYTHON_VERSION_SENTINAL_LABEL")
load("//python/private:utils.bzl", "resolve_py_interpreter_from_info")

def _resolve_py_interpreter_for_version(ctx):
    version = ctx.attr.python_version[PyVersionInfo].version
    toolchain = ctx.toolchains[PYTHON_TOOLCHAIN]

    info = toolchain.interpreters.get(version)

    if info == None:
        fail("Failed to get Python interpreter version '%s' for '%s'. " +
             "Ensure that an interpreter for this version is defined via 'py_interpreter' and avialable for this platform" % (version, ctx.attr.name))

    return resolve_py_interpreter_from_info(info, ctx.attr.name)

def _py_binary_rule_imp(ctx):
    interpreter = _resolve_py_interpreter_for_version(ctx)
    main = ctx.file.main

    if len(ctx.attr.deps) != 1:
        fail("Expected one dependency label in 'deps' attribute, got %s" % str(len(ctx.attr.deps)))

    library_info = ctx.attr.deps[0][PyInfo]
    imports = library_info.imports.to_list()

    entry = ctx.actions.declare_file(ctx.attr.name)
    env = dict({
        "BAZEL_TARGET": ctx.label,
        "BAZEL_WORKSPACE": ctx.workspace_name,
    }, **ctx.attr.env)

    ctx.actions.expand_template(
        template = ctx.file._entry,
        output = entry,
        substitutions = {
            "$PYTHON_INTERPRETER_PATH$": interpreter.bin,
            "$EXPECTED_INTERPRETER_VERSION$": interpreter.expected_version_info.version,
            "$BINARY_ENTRY_POINT$": main.short_path,
            "%BAZEL_WORKSPACE_NAME%": ctx.workspace_name,
            "\"$PYTHON_PATHS$\"": ",\n".join(['"{}"'.format(imp) for imp in imports]).strip(),
            "\"$PYTHON_ENV$\"": ",\n".join(['("{}", "{}")'.format(k, v) for k, v in env.items()]).strip(),
        },
        is_executable = True,
    )

    transitive_files = depset(
        transitive = [
            library_info.transitive_sources,
            interpreter.files,
        ],
    )

    return [
        DefaultInfo(
            files = depset([entry]),
            runfiles = ctx.runfiles(
                files = [main],
                transitive_files = transitive_files,
                collect_data = True,
            ),
            executable = entry,
        ),
        # Return PyInfo.
        # Return PyVersionInfo / PyInterpreterInfo so upstream consumers can see what version of Python this was run with,
    ]

_py_base = struct(
    attrs = dict({
        "env": attr.string_dict(
            mandatory = False,
            default = {},
        ),
        "deps": attr.label_list(
            mandatory = True,
            providers = [PyInfo],
        ),
        "main": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "python_version": attr.label(
            providers = [PyVersionInfo],
            default = DEFAULT_PYTHON_VERSION_SENTINAL_LABEL,
        ),
        "_entry": attr.label(
            allow_single_file = True,
            default = "//python/private:entry.py.tmpl",
        ),
    }),
    toolchains = [
        PYTHON_TOOLCHAIN,
    ],
)

_py_binary = rule(
    implementation = _py_binary_rule_imp,
    attrs = _py_base.attrs,
    toolchains = _py_base.toolchains,
    executable = True,
)

_py_test = rule(
    implementation = _py_binary_rule_imp,
    attrs = _py_base.attrs,
    toolchains = _py_base.toolchains,
    test = True,
)

def py_library(**kwargs):
    native.py_library(**kwargs)

def py_binary(name, main, tags = [], **kwargs):
    library = "_%s" % name
    py_library(
        name = library,
        srcs = kwargs.pop("srcs", []),
        deps = kwargs.pop("deps", []),
        imports = kwargs.pop("imports", []) + ["."],
        data = kwargs.pop("data", []),
        tags = tags,
    )

    _py_binary(
        name = name,
        tags = tags,
        main = main,
        deps = [library],
        **kwargs
    )

def py_test(name, main = None, tags = [], **kwargs):
    library = "_%s" % name
    srcs = kwargs.pop("srcs", [])

    py_library(
        name = library,
        srcs = srcs,
        deps = kwargs.pop("deps", []),
        imports = kwargs.pop("imports", []) + ["."],
        data = kwargs.pop("data", []),
        tags = tags,
    )

    _py_test(
        name = name,
        tags = tags,
        main = main if main != None else srcs[0],
        deps = [library],
        **kwargs
    )
