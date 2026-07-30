# shellcheck shell=sh
# ============================================================
# File:    tests/update/update_spec.sh
# Purpose: Behavior tests for managed MDTK automatic updates.
# Author:  MDTK Team
# Date:    2026-07-29
# ============================================================
#
# Description
#   Uses an isolated XDG managed checkout and a fake bootstrap installer.
#   Covers default/tag/branch refs, empty and large input, unsafe/unmanaged
#   roots, installer failure, and help without network or real Git changes.
#
# Run
#   make testone FILE=tests/update/update_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/update/update.zsh"

_MDTK_UPDATE_TMP="$(mktemp -d)"

mdtk_update_setup() {
    rm -rf "${_MDTK_UPDATE_TMP}"
    mkdir -p "${_MDTK_UPDATE_TMP}/home" "${_MDTK_UPDATE_TMP}/data/mdtk/.git"
    export HOME="${_MDTK_UPDATE_TMP}/home"
    export XDG_DATA_HOME="${_MDTK_UPDATE_TMP}/data"
    export MDTK_UPDATE_ROOT="${XDG_DATA_HOME}/mdtk"
    mkdir -p "${_MDTK_UPDATE_TMP}/bin"
    cat > "${_MDTK_UPDATE_TMP}/bin/git" <<'EOF'
#!/bin/sh
if [ "${MDTK_TEST_UPDATE_ORIGIN_FAIL:-0}" = "1" ]; then
    exit 1
fi
echo "${MDTK_TEST_UPDATE_ORIGIN:-https://github.com/JoyJeeo/mdtk.git}"
EOF
    chmod +x "${_MDTK_UPDATE_TMP}/bin/git"
    export PATH="${_MDTK_UPDATE_TMP}/bin:/usr/bin:/bin"
    echo "$MDTK_UPDATE_MARKER_CONTENT" > "${MDTK_UPDATE_ROOT}/.mdtk-managed-install"
    cat > "${MDTK_UPDATE_ROOT}/install.sh" <<'EOF'
#!/usr/bin/env zsh
echo "ref=${MDTK_INSTALL_REF:-}"
echo "channel=${MDTK_INSTALL_CHANNEL:-}"
echo "managed-mode=${MDTK_BOOTSTRAP_MANAGED_MODE:-}"
echo "repository=${MDTK_INSTALL_REPOSITORY_URL:-}"
[[ "${MDTK_TEST_UPDATE_FAIL:-0}" != "1" ]]
EOF
    unset MDTK_TEST_UPDATE_FAIL
    unset MDTK_TEST_UPDATE_ORIGIN
    unset MDTK_TEST_UPDATE_ORIGIN_FAIL
}

_mdtk_update_large_ref() {
    local ref="feature/"
    local i
    for i in {1..200}; do
        ref="${ref}x"
    done
    mdtk_update_dispatch --ref "$ref"
}

Describe 'mdtk update'
    BeforeEach 'mdtk_update_setup'

    It 'updates a managed installation through the stable channel by default'
        When call mdtk_update_dispatch
        The output should include 'Updating MDTK channel: stable'
        The output should include 'ref='
        The output should include 'managed-mode=1'
        The output should include 'repository=https://github.com/JoyJeeo/mdtk.git'
        The status should be successful
    End

    It 'updates the development channel with --coder'
        When call mdtk_update_dispatch --coder
        The output should include 'Updating MDTK channel: development (ref=main)'
        The output should include 'ref=main'
        The output should include 'channel=development'
        The status should be successful
    End

    It 'rejects combining --coder with --ref'
        When call mdtk_update_dispatch --coder --ref v0.1.2
        The error should include 'cannot be combined'
        The status should be failure
    End

    It 'forwards a requested tag to the managed installer'
        When call mdtk_update_dispatch --ref v0.1.1
        The output should include 'ref=v0.1.1'
        The status should be successful
    End

    It 'preserves a custom managed repository origin'
        export MDTK_TEST_UPDATE_ORIGIN="git@example.com:team/mdtk.git"
        When call mdtk_update_dispatch --ref stable
        The output should include 'repository=git@example.com:team/mdtk.git'
        The status should be successful
    End

    It 'forwards a branch containing a slash'
        When call mdtk_update_dispatch --ref feature/stable
        The output should include 'ref=feature/stable'
        The status should be successful
    End

    It 'forwards large ref input for installer validation'
        When call _mdtk_update_large_ref
        The output should include 'ref=feature/'
        The status should be successful
    End

    It 'rejects an empty ref option'
        When call mdtk_update_dispatch --ref
        The error should include 'requires a branch or tag'
        The status should be failure
    End

    It 'rejects an unknown option'
        When call mdtk_update_dispatch --bogus
        The output should include 'Usage:'
        The error should include 'Unknown update option:'
        The status should be failure
    End

    It 'prints help without running the installer'
        When call mdtk_update_dispatch --help
        The output should include 'Usage: mdtk update'
        The output should not include 'managed-mode=1'
        The status should be successful
    End

    It 'refuses an ordinary source checkout without a marker'
        rm -f "${MDTK_UPDATE_ROOT}/.mdtk-managed-install"
        When call mdtk_update_dispatch
        The error should include 'requires an MDTK-managed installation'
        The status should be failure
    End

    It 'refuses an incorrect managed marker'
        echo 'not-managed' > "${MDTK_UPDATE_ROOT}/.mdtk-managed-install"
        When call mdtk_update_dispatch
        The error should include 'requires an MDTK-managed installation'
        The status should be failure
    End

    It 'refuses a marked checkout outside the XDG managed path'
        export MDTK_UPDATE_ROOT="${_MDTK_UPDATE_TMP}/other/mdtk"
        mkdir -p "${MDTK_UPDATE_ROOT}/.git"
        echo "$MDTK_UPDATE_MARKER_CONTENT" > "${MDTK_UPDATE_ROOT}/.mdtk-managed-install"
        : > "${MDTK_UPDATE_ROOT}/install.sh"
        When call mdtk_update_dispatch
        The error should include 'requires an MDTK-managed installation'
        The status should be failure
    End

    It 'propagates installer failure'
        export MDTK_TEST_UPDATE_FAIL=1
        When call mdtk_update_dispatch --ref v9.9.9
        The output should include 'ref=v9.9.9'
        The status should be failure
    End

    It 'fails before update when the managed origin cannot be verified'
        export MDTK_TEST_UPDATE_ORIGIN_FAIL=1
        When call mdtk_update_dispatch
        The error should include 'Could not verify the managed installation origin.'
        The output should not include 'Updating MDTK'
        The status should be failure
    End
End
