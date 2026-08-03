# shellcheck shell=sh
# ============================================================
# File:    tests/install/dev_install_spec.sh
# Purpose: Tests for developer-installer presentation (Issue #051).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Runs the developer installer against an isolated fake conda prefix with
#   preinstalled tool shims. No packages, real environment, or user links are
#   changed. Covers success, failure, Unicode/whitespace paths, and NO_COLOR.
#
# Run
#   make testone FILE=tests/install/dev_install_spec.sh
# ============================================================

MDTK_DEV_INSTALL="${SHELLSPEC_PROJECT_ROOT}/scripts/dev-install.zsh"
_MDTK_DEV_INSTALL_TMP="$(mktemp -d)"

mdtk_dev_install_setup() {
    rm -rf "${_MDTK_DEV_INSTALL_TMP}"
    mkdir -p "${_MDTK_DEV_INSTALL_TMP}/环境 with space/bin"
    printf '#!/bin/sh\nexit 0\n' > "${_MDTK_DEV_INSTALL_TMP}/环境 with space/bin/shellspec"
    printf '#!/bin/sh\nexit 0\n' > "${_MDTK_DEV_INSTALL_TMP}/环境 with space/bin/shellcheck"
    chmod +x "${_MDTK_DEV_INSTALL_TMP}/环境 with space/bin/shellspec"
    chmod +x "${_MDTK_DEV_INSTALL_TMP}/环境 with space/bin/shellcheck"
}

_mdtk_dev_install_run() {
    CONDA_DEFAULT_ENV=mdtk \
        CONDA_PREFIX="${_MDTK_DEV_INSTALL_TMP}/环境 with space" \
        zsh "$MDTK_DEV_INSTALL"
}

_mdtk_dev_install_wrong_env() {
    CONDA_DEFAULT_ENV=base \
        CONDA_PREFIX="${_MDTK_DEV_INSTALL_TMP}/base" \
        zsh "$MDTK_DEV_INSTALL"
}

Describe 'mdtk developer installer'
    BeforeEach 'mdtk_dev_install_setup'

    It 'uses aligned labels without icons or ANSI when color is disabled'
        export NO_COLOR=1
        When call _mdtk_dev_install_run
        The output should include '[INFO]    Conda env:    mdtk'
        The output should include '[SUCCESS] shellspec already installed'
        The output should include '[SUCCESS] All set. Try:'
        The output should not include $'\033['
        The status should be successful
    End

    It 'creates only the isolated conda-prefix command link'
        export NO_COLOR=1
        _mdtk_dev_install_run >/dev/null
        When call test -L "${_MDTK_DEV_INSTALL_TMP}/环境 with space/bin/mdtk"
        The status should be successful
    End

    It 'prints aligned colored errors outside the mdtk environment'
        unset NO_COLOR
        When call _mdtk_dev_install_wrong_env
        The error should include $'\033['
        The error should include '[ERROR]'
        The error should include '[INFO]'
        The status should be failure
    End
End
