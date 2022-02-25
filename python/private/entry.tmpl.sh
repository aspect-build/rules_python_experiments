#!/usr/bin/env bash

set -e

PWD=$(pwd)

# Resolved from the py_interpreter via PyInterpreterInfo.
PYTHON="$PYTHON_INTERPRETER_PATH$"
PIP="${PWD}/$PIP_PATH$"
PTH_FILE="${PWD}/$PTH_FILE_PATH$"
PYTHON_SITE_PACKAGES=$(${PYTHON} $INTERPRETER_FLAGS$ -c 'import site; print(site.getsitepackages()[0])')

ENTRYPOINT="$BINARY_ENTRY_POINT$"

# Convenience vars for the Python virtual env that's created.
VENV_PATH="$VENV_PATH$"
VBIN="${VENV_PATH}/bin"
VPIP="${VBIN}/pip3"
VPYTHON="${VBIN}/python3"

# Create a virtual env to run inside. This allows us to not have to manipulate the PYTHON_PATH to find external
# dependencies.
# We can also now specify the `-I` (isolated) flag to Python, stopping Python from adding the script path to sys.path[0]
# which we have no control over otherwise.
# This does however have some side effects as now all other PYTHON* env vars are ignored.

# The venv is intentionally created without pip, as when the venv is created with pip, `ensurepip` is used which will
# use the bundled version of pip, which does not match the version of pip bundled with the interpreter distro.
# So we symlink in this ourselves.
VENV_FLAGS=(
  "--without-pip"
  "--clear"
)
"${PYTHON}" $INTERPRETER_FLAGS$ -m venv "$VENV_PATH" "${VENV_FLAGS[@]}"

# Now symlink in pip from the toolchain
# Also link to `pip` as well as `pip3`. Python venv will also link `pip3.x`, but this seems unnecessary for this use
ln -snf "${PIP}" "${VPIP}"
ln -snf "${PIP}" "${VBIN}/pip"

# Activate the venv
. "${VBIN}/activate"

# Need to symlink in the pip site-packages folder not just the binary.
# Ask Python where the site-packages folder is and symlink the pip package in from the toolchain
VENV_SITE_PACKAGES=$("${VPYTHON}" $INTERPRETER_FLAGS$ -c 'import site; print(site.getsitepackages()[0])')
ln -snf "${PYTHON_SITE_PACKAGES}/pip" "${VENV_SITE_PACKAGES}/pip"

INSTALL_WHEELS=$INSTALL_WHEELS$
if [ "$INSTALL_WHEELS" = true ]; then
  # Call to pip to "install" our dependencies. The `--find-links` flag point to the external downloaded wheels in the "wheelhouse",
  # directory, while `--no-index` ensures we don't reach out to PyPi
  WHEEL_HOUSE="$WHEEL_HOUSE$"
  PIP_FLAGS=(
    "--quiet"
    "--no-compile"
    "--require-virtualenv"
    "--no-input"
    "--no-cache-dir"
    "--disable-pip-version-check"
    "--no-python-version-warning"
    "--only-binary=:all:"
    "--require-hashes"
    "--no-dependencies"
    "--no-index"
    "--find-links=${WHEEL_HOUSE}"
  )

  "${VPIP}" install "${PIP_FLAGS[@]}" -r $REQUIREMENTS_LOCKED$
fi

#CREATE_VENV_CONVENIENCE_SYMLINKS=true
#if [ "$CREATE_VENV_CONVENIENCE_SYMLINKS" = true ]; then
#
#fi

# Symlink in the .pth file containing all our first party dependency paths. These are from all direct and transitive
# py_library rules.
# The .pth file adds to the interpreters sys.path, without having to set `PYTHONPATH`. This allows us to still
# run with the interpreter with the `-I` flag. This stops some import mechanisms breaking out the sandbox by using
# relative imports.
ln -snf "${PTH_FILE}" "${VENV_SITE_PACKAGES}/first_party.pth"

# Set all the env vars here, just before we launch
$PYTHON_ENV$

# We can stop here an not run the py_binary / py_test entrypoint and just create the venv.
# This can be useful for editor support.
RUN_BINARY_ENTRY_POINT=$RUN_BINARY_ENTRY_POINT$
if [ "$RUN_BINARY_ENTRY_POINT" = true ]; then
  # Finally, launch the entrypoint
  "${VPYTHON}" $INTERPRETER_FLAGS$ -I "${ENTRYPOINT}"
fi

# Unset any set env vars
$PYTHON_ENV_UNSET$
