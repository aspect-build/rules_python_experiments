workspace(name = "aspect_rules_python_experiments")

load(":internal_deps.bzl", "rules_python_experiments_internal_deps")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

rules_python_experiments_internal_deps()

load("//python:repositories.bzl", "python_register_toolchains", "rules_python_experiments_dependencies")

rules_python_experiments_dependencies()

python_register_toolchains(
    name = "pythons",
    default_python_version = "3.10",
    python_versions = [
        "3.9",
        "3.10",
    ],
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.3")

gazelle_dependencies()

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies")

aspect_bazel_lib_dependencies()

http_archive(
    name = "rules_python",
    sha256 = "a30abdfc7126d497a7698c29c46ea9901c6392d6ed315171a6df5ce433aa4502",
    strip_prefix = "rules_python-0.6.0",
    url = "https://github.com/bazelbuild/rules_python/archive/0.6.0.tar.gz",
)

load("@rules_python//python/pip_install:repositories.bzl", "pip_install_dependencies")

pip_install_dependencies()

load("@rules_python//python:pip.bzl", "pip_parse")

pip_parse(
    name = "pypi",
    python_interpreter_target = "@pythons_aarch64-apple-darwin//:python3",
    requirements_lock = "//python/tests:requirements.txt",
)

load("@pypi//:requirements.bzl", "install_deps")

install_deps()
