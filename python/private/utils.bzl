load("//python/private:providers.bzl", "PyVersionInfo")

def resolve_py_interpreter_from_info(info, caller):
    files = [target.files for target in info.files]
    bin = info.interpreter_path

    if bin == "":
        bin = info.interpreter.files.to_list()[0].short_path
        files.append(info.interpreter.files)

    if bin == None or len(bin) == 0:
        fail("Failed to get Python interpreter version '%s' for '%s'. Must define either interpreter, or interpreter_path" % (info.version, caller))

    return struct(
        info = info,
        bin = bin,
        files = depset(transitive = files),
        expected_version_info = info.version[PyVersionInfo],
    )

def dict_to_exports(env):
    return [
        "export %s=\"%s\"" % (k, v)
        for (k, v) in env.items()
    ]
