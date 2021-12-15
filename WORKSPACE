workspace(name = "com_aspect_build_rules_python_experiments")

load(":internal_deps.bzl", "rules_python_experiments_internal_deps")

rules_python_experiments_internal_deps()

load("//python:repositories.bzl", "python_register_toolchains", "rules_python_experiments_dependencies")

rules_python_experiments_dependencies()

python_register_toolchains(
    name = "python1_14",
    python_version = "1.14.2",
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.3")

gazelle_dependencies()
