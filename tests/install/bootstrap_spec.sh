# shellcheck shell=sh
# ============================================================
# File:    tests/install/bootstrap_spec.sh
# Purpose: Tests for the local/remote top-level installer bootstrap.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   Uses fake git/uname commands and an isolated HOME/XDG data root.
#   Covers local delegation, stdin remote installation, managed update,
#   missing Git, unmarked targets, clone failure, and whitespace paths.
#
# Run
#   make testone FILE=tests/install/bootstrap_spec.sh
# ============================================================

MDTK_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/install.sh"
_MDTK_BOOTSTRAP_TMP="$(mktemp -d)"

mdtk_bootstrap_setup() {
    rm -rf "${_MDTK_BOOTSTRAP_TMP}"
    mkdir -p "${_MDTK_BOOTSTRAP_TMP}/home"
    mkdir -p "${_MDTK_BOOTSTRAP_TMP}/fake-bin"
    mkdir -p "${_MDTK_BOOTSTRAP_TMP}/fixture/bin"
    mkdir -p "${_MDTK_BOOTSTRAP_TMP}/fixture/scripts"

    {
        echo '#!/usr/bin/env zsh'
        echo 'echo "fixture mdtk"'
    } > "${_MDTK_BOOTSTRAP_TMP}/fixture/bin/mdtk"
    chmod +x "${_MDTK_BOOTSTRAP_TMP}/fixture/bin/mdtk"
    {
        echo '#!/usr/bin/env zsh'
        echo 'echo "fixture checkout installer ran"'
    } > "${_MDTK_BOOTSTRAP_TMP}/fixture/scripts/install.sh"

    {
        echo '#!/bin/sh'
        echo 'echo Darwin'
    } > "${_MDTK_BOOTSTRAP_TMP}/fake-bin/uname"
    chmod +x "${_MDTK_BOOTSTRAP_TMP}/fake-bin/uname"

    cat > "${_MDTK_BOOTSTRAP_TMP}/fake-bin/git" <<'EOF'
#!/bin/sh
if [ "${MDTK_TEST_GIT_FAIL:-0}" = "1" ]; then
    exit 1
fi
if [ "$1" = "clone" ]; then
    for last do :; done
    mkdir -p "$last"
    cp -R "${MDTK_TEST_FIXTURE}/." "$last"
    mkdir -p "$last/.git"
    exit 0
fi
if [ "$1" = "-C" ]; then
    target="$2"
    if [ "$3" = "remote" ]; then
        echo "${MDTK_TEST_ORIGIN_URL:-https://github.com/JoyJeeo/mdtk.git}"
        exit 0
    fi
    if [ "$3" = "rev-parse" ]; then
        echo "main"
        exit 0
    fi
    if [ "$3" = "pull" ]; then
        touch "$target/.updated-by-test"
        exit 0
    fi
fi
exit 1
EOF
    chmod +x "${_MDTK_BOOTSTRAP_TMP}/fake-bin/git"

    export HOME="${_MDTK_BOOTSTRAP_TMP}/home"
    export XDG_DATA_HOME="${_MDTK_BOOTSTRAP_TMP}/xdg-data"
    export MDTK_TEST_FIXTURE="${_MDTK_BOOTSTRAP_TMP}/fixture"
    export PATH="${_MDTK_BOOTSTRAP_TMP}/fake-bin:/usr/bin:/bin"
    unset MDTK_TEST_GIT_FAIL
    unset MDTK_TEST_ORIGIN_URL
    unset MDTK_INSTALL_REPOSITORY_URL
    unset MDTK_INSTALL_BRANCH
}

_mdtk_bootstrap_run_remote() {
    zsh < "$MDTK_BOOTSTRAP"
}

_mdtk_bootstrap_remote_and_verify() {
    local output
    output="$(_mdtk_bootstrap_run_remote 2>&1)" || return 1
    echo "$output"
    local root="${XDG_DATA_HOME}/mdtk"
    [[ -x "${root}/bin/mdtk" ]] || return 1
    [[ "$(<"${root}/.mdtk-managed-install")" == "managed-by=mdtk-bootstrap-v1" ]] || return 1
}

Describe 'top-level install bootstrap'
    BeforeEach 'mdtk_bootstrap_setup'

    It 'delegates when run from a local checkout'
        local checkout="${_MDTK_BOOTSTRAP_TMP}/local-checkout"
        mkdir -p "${checkout}/scripts" "${checkout}/bin"
        cp "$MDTK_BOOTSTRAP" "${checkout}/install.sh"
        cp "${_MDTK_BOOTSTRAP_TMP}/fixture/scripts/install.sh" "${checkout}/scripts/install.sh"
        cp "${_MDTK_BOOTSTRAP_TMP}/fixture/bin/mdtk" "${checkout}/bin/mdtk"
        chmod +x "${checkout}/bin/mdtk"
        When run zsh "${checkout}/install.sh"
        The status should be successful
        The output should include 'Installing from local checkout:'
        The output should include 'fixture checkout installer ran'
    End

    It 'installs from empty stdin arguments into the XDG data directory'
        When call _mdtk_bootstrap_remote_and_verify
        The status should be successful
        The output should include 'Downloading MDTK.'
        The output should include 'MDTK is ready.'
    End

    It 'updates an existing marked installation idempotently'
        _mdtk_bootstrap_run_remote >/dev/null
        _mdtk_bootstrap_run_remote >/dev/null
        When call test -f "${XDG_DATA_HOME}/mdtk/.updated-by-test"
        The status should be successful
    End

    It 'refuses to update a managed checkout from a different origin'
        _mdtk_bootstrap_run_remote >/dev/null
        export MDTK_TEST_ORIGIN_URL="https://example.invalid/not-mdtk.git"
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The error should include 'origin or branch does not match'
        The path "${XDG_DATA_HOME}/mdtk/.updated-by-test" should not be exist
    End

    It 'refuses to overwrite an unmarked existing directory'
        mkdir -p "${XDG_DATA_HOME}/mdtk"
        echo "keep" > "${XDG_DATA_HOME}/mdtk/sentinel"
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The error should include 'is not managed by MDTK'
        The path "${XDG_DATA_HOME}/mdtk/sentinel" should be file
    End

    It 'fails clearly when Git is unavailable'
        rm -f "${_MDTK_BOOTSTRAP_TMP}/fake-bin/git"
        export PATH="${_MDTK_BOOTSTRAP_TMP}/fake-bin:/bin"
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The error should include 'Git is required.'
    End

    It 'leaves no checkout behind when clone fails'
        export MDTK_TEST_GIT_FAIL=1
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The output should include 'Downloading MDTK.'
        The error should include 'Could not download MDTK.'
        The path "${XDG_DATA_HOME}/mdtk" should not be exist
    End

    It 'supports an XDG data path containing whitespace and Unicode'
        export XDG_DATA_HOME="${_MDTK_BOOTSTRAP_TMP}/数据 with space"
        When call _mdtk_bootstrap_remote_and_verify
        The status should be successful
        The output should include 'MDTK is ready.'
    End
End
