"""Unit tests for starlark helpers
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//python/private:versions.bzl", "MINOR_MAPPING", "TOOL_VERSIONS")

required_platforms = [
    "x86_64-apple-darwin",
    "x86_64-unknown-linux-gnu",
]

def _smoke_test_impl(ctx):
    env = unittest.begin(ctx)
    for version in TOOL_VERSIONS.keys():
        platforms = TOOL_VERSIONS[version]
        for required_platform in required_platforms:
            asserts.true(
                env,
                required_platform in platforms.keys(),
                "Missing platform {} for version {}".format(required_platform, version),
            )
    for minor in MINOR_MAPPING:
        version = MINOR_MAPPING[minor]
        asserts.true(
            env,
            version in TOOL_VERSIONS.keys(),
            "Missing version {} in TOOL_VERSIONS".format(version),
        )
    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
_t0_test = unittest.make(_smoke_test_impl)

def versions_test_suite(name):
    unittest.suite(name, _t0_test)
