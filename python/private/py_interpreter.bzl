load("//python/private:providers.bzl", "PyInterpreterInfo", "PyVersionInfo")
load("//python/private:utils.bzl", "dict_to_exports", "resolve_py_interpreter_from_info")

def _launcher(ctx, interpreter, module = "$@", content = []):
    return "\n".join([
        "#!/usr/bin/env sh",
        "",
        "\n".join(dict_to_exports(ctx.attr.env)),
        "PYTHON=`pwd`/{bin}".format(
            bin = interpreter.bin,
        ),
        "cd $BUILD_WORKSPACE_DIRECTORY",
        "$PYTHON {flags} {module}".format(
            flags = " ".join(ctx.attr.default_interpreter_flags),
            module = module,
        ),
    ] + content)

def _py_interpreter(ctx):
    interpreter_path = ctx.attr.interpreter_path
    interpreter = ctx.attr.interpreter

    if interpreter == None and interpreter_path == "":
        fail("Must define either 'interpreter' or 'interpreter_path' for py_interpreter rule '%s'" % ctx.attr.name)

    py_interpreter_info = PyInterpreterInfo(
        version = ctx.attr.version,
        interpreter_path = interpreter_path,
        interpreter = interpreter,
        files = ctx.attr.files,
        flags = ctx.attr.default_interpreter_flags,
        env = ctx.attr.env,
    )

    py_interpreter = resolve_py_interpreter_from_info(py_interpreter_info, ctx.attr.name)

    launcher_bin = ctx.actions.declare_file("python_%s.sh" % ctx.attr.name)
    ctx.actions.write(
        output = launcher_bin,
        is_executable = True,
        content = _launcher(ctx, py_interpreter),
    )

    venv_bin = ctx.actions.declare_file("venv_%s.sh" % ctx.attr.name)
    ctx.actions.write(
        output = venv_bin,
        is_executable = True,
        content = _launcher(
            ctx,
            py_interpreter,
            "-m venv --clear $@",
            [
                "echo 'Python virtual environment created!'",
            ],
        ),
    )

    pip_bin = ctx.actions.declare_file("pip_%s.sh" % ctx.attr.name)
    ctx.actions.write(
        output = pip_bin,
        is_executable = True,
        content = _launcher(
            ctx,
            py_interpreter,
            "-m pip $@",
        ),
    )

    return [
        DefaultInfo(
            files = depset([launcher_bin]),
            runfiles = ctx.runfiles(ctx.files.files),
            executable = launcher_bin,
        ),
        OutputGroupInfo(
            venv_bin = [venv_bin],
            pip_bin = [pip_bin],
        ),
        py_interpreter_info,
    ]

py_interpreter = rule(
    implementation = _py_interpreter,
    attrs = {
        "version": attr.label(
            mandatory = True,
            doc = "Version of this interpreter, provided by the py_version rule",
            providers = [PyVersionInfo],
        ),
        "interpreter": attr.label(
            allow_single_file = True,
            doc = "When using an interpreter built from source, this is the label of the rule that will build the interpreter",
        ),
        "files": attr.label_list(
            allow_files = True,
            doc = "List of files assoicated with the interpreter",
        ),
        "interpreter_path": attr.string(
            default = "",
            doc = "When using an interpreter on the machine where the action is running, then this is the path to the Python interpreter executable",
        ),
        "default_interpreter_flags": attr.string_list(
            default = ["-B", "-s"],
            doc = "A set of flags set on the invocation of the Python interpreter",
        ),
        "env": attr.string_dict(
            default = {
                "PYTHONHASHSEED": "1",
            },
            doc = "A set of enviournment variables set on each invocation of the Python interpreter",
        ),
    },
    provides = [PyInterpreterInfo],
    doc = "",
    executable = True,
)
