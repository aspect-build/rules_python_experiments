"""Providers"""

PyVersionInfo = provider(
    "Info for a Python version",
    fields = {
        "version": "The version string for the interpreter, in the form x.y.z",
    },
)

PyInterpreterInfo = provider(
    "Info for a python interpreter at a given version",
    fields = {
        "env": "Envirounment variables to set for the interpreter",
        "files": "Assoicated files for the interpreter",
        "flags": "Flags to set when calling this interpreter",
        "interpreter": "A label that references the binary of a in build interpreter",
        "interpreter_path": "Full path to the interpreter binary",
        "pip": "A label that represents the pip binary for this interpreter",
        "version": "The version string for the interpreter, in the form x.y.z",
    },
)

PyWheelInfo = provider(
    "Info for python wheel dependencies",
    fields = {
        "srcs": "A depset of wheels for the providing target",
        "transitive_srcs": "A depset of wheels including those from the transitive dependencies",
    },
)
