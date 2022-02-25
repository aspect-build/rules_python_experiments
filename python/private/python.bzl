""

load("//python/private:py_library.bzl", _py_library = "py_library")
load("//python/private:providers.bzl", "PyVersionInfo", "PyWheelInfo")
load("//python/private:toolchain.bzl", "PYTHON_TOOLCHAIN")
load("//python/private:py_version.bzl", "DEFAULT_PYTHON_VERSION_SENTINAL_LABEL")
load("//python/private:utils.bzl", "resolve_py_interpreter_from_info", "dict_to_exports")

def _resolve_py_interpreter_for_version(ctx):
    version = ctx.attr.python_version[PyVersionInfo].version
    toolchain = ctx.toolchains[PYTHON_TOOLCHAIN]

    info = toolchain.interpreters.get(version)

    if info == None:
        fail("Failed to get Python interpreter version '%s' for '%s'. " +
             "Ensure that an interpreter for this version is defined via 'py_interpreter' and avialable for this platform" % (version, ctx.attr.name))

    return resolve_py_interpreter_from_info(info, ctx.attr.name)

def _symlink_to_wheel_house(ctx, wheel_house, whl_file):
    wheel_house_file = ctx.actions.declare_file(
        "{wheel_house}/{whl}".format(
            wheel_house = wheel_house,
            whl = whl_file.basename,
        ),
    )

    ctx.actions.symlink(output = wheel_house_file, target_file = whl_file)

    return wheel_house_file

def _py_binary_rule_imp(ctx):
    interpreter = _resolve_py_interpreter_for_version(ctx)
    main = ctx.file.main

    if len(ctx.attr.deps) != 1:
        fail("Expected one dependency label in 'deps' attribute, got %s" % str(len(ctx.attr.deps)))

    runfiles_files = [
        main,
    ]

    entry = ctx.actions.declare_file(ctx.attr.name)
    env = dict({
        "BAZEL_TARGET": ctx.label,
        "BAZEL_WORKSPACE": ctx.workspace_name,
        "BAZEL_TARGET_NAME": ctx.attr.name,
    }, **ctx.attr.env)

    wheel_house_dir = ".%s_wheelhouse" % ctx.attr.name
    wheel_house_files = []
    for whl in ctx.attr.wheels:
        info = whl[DefaultInfo]
        whl_file = info.files.to_list()[0]

        wheel_house_files.append(
            _symlink_to_wheel_house(ctx, wheel_house_dir, whl_file),
        )

        for file in info.default_runfiles.files.to_list():
            wheel_house_files.append(
                _symlink_to_wheel_house(ctx, wheel_house_dir, file),
            )

    if len(wheel_house_files) > 0:
        runfiles_files.extend(wheel_house_files)

    # Create a depset from the `imports` depsets, then pass this to Args to create the `.pth` file.
    # This avoids having to call `.to_list` on the depset and taking the perf hit
    imports_depset = depset(
        transitive = [
            dep[PyInfo].imports
            for dep in ctx.attr.deps
            if PyInfo in dep
        ],
    )

    pth_file = ctx.actions.declare_file("%s_first_party.pth" % ctx.attr.name)
    runfiles_files.append(pth_file)
    pth_lines = ctx.actions.args()

    # The venv is created next to the `main` file. Paths in the .pth are relative to the site-packages folder where they
    # reside. All "import" paths from `py_library` start with the workspace name, so we need to go back up the tree for
    # each segment from site-packages in the venv + `main.dirname`, then once more to get to the root of the runfiles.
    # Four .. will get us back to the root of the venv:
    # .{name}.venv/lib/python{version}/site-packages/first_party.pth
    escape = ([".."] * (5 + len(main.dirname.split("/"))))
    pth_lines.add_all(imports_depset, format_each = "/".join(escape) + "/%s")

    ctx.actions.write(
        output = pth_file,
        content = pth_lines,
    )

    # Convenience symlinks for venv:
    # Symlink the library root containing all its files (inc transitive) into the site-packages folder. As we don't know
    # where the root of the library is, currently assume that `imports` is being used and contains a single entry (this likely
    # won't work in practice). The the `root` is one segment forward from the import path.
    srcs_depset = depset(
        transitive = [
            dep[PyInfo].transitive_sources
            for dep in ctx.attr.deps
            if PyInfo in dep
        ],
    )

    requirements_locked_path = "__NONE__"
    if ctx.file.requirements_locked:
        requirements_locked_path = ctx.file.requirements_locked.short_path
        runfiles_files.append(ctx.file.requirements_locked)

    common_substitutions = {
        "$BAZEL_WORKSPACE_NAME$": ctx.workspace_name,
        "$BINARY_ENTRY_POINT$": main.short_path,
        "$EXPECTED_INTERPRETER_VERSION$": interpreter.expected_version_info.version,
        "$INTERPRETER_FLAGS$": " ".join(interpreter.info.flags),
        "$INTERPRETER_FLAGS_PARTS$": " ".join(['"%s", ' % f for f in interpreter.info.flags]),
        "$INSTALL_WHEELS$": str(len(wheel_house_files) > 0).lower(),
        "$PIP_PATH$": interpreter.info.pip.path,
        "$PTH_FILE_PATH$": pth_file.short_path,
        "$PYTHON_INTERPRETER_PATH$": interpreter.bin,
        "$REQUIREMENTS_LOCKED$": requirements_locked_path,
        "$RUN_BINARY_ENTRY_POINT$": "true",
        "$VENV_PATH$": "/".join([main.dirname, ".%s_venv" % ctx.attr.name]),
        "$WHEEL_HOUSE$": "/".join([main.dirname, wheel_house_dir]),
        "$PYTHON_ENV$": "\n".join(dict_to_exports(env)).strip(),
        "$PYTHON_ENV_UNSET$": "\n".join(["unset %s" % k for k in env.keys()]).strip(),
    }

    ctx.actions.expand_template(
        template = ctx.file._entry,
        output = entry,
        substitutions = common_substitutions,
        is_executable = True,
    )

    create_venv_bin = ctx.actions.declare_file("%s_create_venv.sh" % ctx.attr.name)
    ctx.actions.expand_template(
        template = ctx.file._entry,
        output = create_venv_bin,
        substitutions = dict(
            common_substitutions,
            **{
                "$RUN_BINARY_ENTRY_POINT$": "false",
                "$VENV_PATH$": "${BUILD_WORKSPACE_DIRECTORY}/$@",
            }
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = runfiles_files,
        transitive_files = depset(
            transitive = [
                interpreter.files,
            ] + [
                target[PyInfo].transitive_sources
                for target in ctx.attr.deps
                if PyInfo in target
            ],
        ),
    )

    runfiles = runfiles.merge_all([
        target[DefaultInfo].default_runfiles
        for target in ctx.attr.wheels
    ])

    runfiles = runfiles.merge_all([
        target[DefaultInfo].default_runfiles
        for target in ctx.attr.deps
    ])

    return [
        DefaultInfo(
            files = depset([entry]),
            runfiles = runfiles,
            executable = entry,
        ),
        OutputGroupInfo(
            create_venv = [create_venv_bin],
        ),
        # Return PyInfo.
        # Return PyVersionInfo / PyInterpreterInfo so upstream consumers can see what version of Python this was run with,
    ]

_py_base = struct(
    attrs = dict({
        "env": attr.string_dict(
            default = {},
        ),
        "deps": attr.label_list(
            providers = [[], [PyInfo], [PyWheelInfo]],
        ),
        "wheels": attr.label_list(
            allow_files = True,
        ),
        "main": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "python_version": attr.label(
            providers = [PyVersionInfo],
            default = DEFAULT_PYTHON_VERSION_SENTINAL_LABEL,
        ),
        "requirements_locked": attr.label(
            allow_single_file = True,
        ),
        "_entry": attr.label(
            allow_single_file = True,
            default = "//python/private:entry.tmpl.sh",
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

def py_binary(name, main, tags = [], **kwargs):
    library = "_%s" % name
    _py_library(
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

    native.filegroup(
        name = "%s_create_venv_files" % name,
        srcs = [name],
        tags = ["manual"],
        output_group = "create_venv",
    )

    native.sh_binary(
        name = "%s.venv" % name,
        tags = ["manual"],
        srcs = [":%s_create_venv_files" % name],
    )

def py_test(name, main = None, tags = [], **kwargs):
    library = "_%s" % name
    srcs = kwargs.pop("srcs", [])

    _py_library(
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

py_library = _py_library
