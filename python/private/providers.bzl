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
        "version": "The version string for the interpreter, in the form x.y.z",
        "interpreter_path": "Full path to the interpreter binary",
        "interpreter": "A label that references the binary of a in build interpreter",
        "files": "Assoicated files for the interpreter",
        "flags": "Flags to set when calling this interpreter",
        "env": "Envirounment variables to set for the interpreter",
    },
)
