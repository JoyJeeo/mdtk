# shellcheck shell=sh
# ============================================================
# File:    tests/release/release_check_spec.sh
# Purpose: Behavior tests for the production release gate (Issue #072).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Runs the release script with mocked make, shellspec, and git commands to
#   cover success plus syntax, normal-test, no-color-test, Smoke, and unfinished
#   marker failures without recursively running the real suite.
#
# Run
#   make testone FILE=tests/release/release_check_spec.sh
# ============================================================

MDTK_RELEASE_SCRIPT="${SHELLSPEC_PROJECT_ROOT}/scripts/release-check.zsh"
_MDTK_RELEASE_TMP="$(mktemp -d)"

# Description: Create deterministic command mocks for the release gate.
# Parameters: none. Return: 0.
# Example: mdtk_release_setup
mdtk_release_setup() {
    rm -rf -- "${_MDTK_RELEASE_TMP}"
    mkdir -p "${_MDTK_RELEASE_TMP}/bin"
    printf '%s\n' \
        '#!/bin/sh' \
        'echo "make:$*"' \
        'if [ "${MDTK_TEST_RELEASE_FAIL:-}" = "$1" ]; then exit 11; fi' \
        > "${_MDTK_RELEASE_TMP}/bin/make"
    printf '%s\n' \
        '#!/bin/sh' \
        'echo "shellspec:NO_COLOR=${NO_COLOR:-0}"' \
        'if [ "${MDTK_TEST_RELEASE_FAIL:-}" = "normal" ] && [ -z "${NO_COLOR:-}" ]; then exit 12; fi' \
        'if [ "${MDTK_TEST_RELEASE_FAIL:-}" = "no_color" ] && [ -n "${NO_COLOR:-}" ]; then exit 13; fi' \
        > "${_MDTK_RELEASE_TMP}/bin/shellspec"
    printf '%s\n' \
        '#!/bin/sh' \
        'if [ "${MDTK_TEST_RELEASE_FAIL:-}" = "markers" ]; then echo "src/fake.zsh:1:TODO"; exit 0; fi' \
        'if [ "${MDTK_TEST_RELEASE_FAIL:-}" = "git_error" ]; then exit 14; fi' \
        'exit 1' \
        > "${_MDTK_RELEASE_TMP}/bin/git"
    chmod +x "${_MDTK_RELEASE_TMP}/bin/make" \
        "${_MDTK_RELEASE_TMP}/bin/shellspec" "${_MDTK_RELEASE_TMP}/bin/git"
    unset NO_COLOR MDTK_TEST_RELEASE_FAIL
}

# Description: Run the release gate with mocked external commands.
# Parameters: $1 optional failure selector. Return: release script status.
# Example: mdtk_release_run "syntax"
mdtk_release_run() {
    local failure="${1:-}"
    PATH="${_MDTK_RELEASE_TMP}/bin:/usr/bin:/bin" \
        MDTK_TEST_RELEASE_FAIL="$failure" NO_COLOR= \
        zsh "$MDTK_RELEASE_SCRIPT"
}

Describe 'production release check'
    BeforeEach 'mdtk_release_setup'

    It 'runs every offline gate in order'
        When call mdtk_release_run
        The output should include 'make:syntax'
        The output should include 'shellspec:NO_COLOR=0'
        The output should include 'shellspec:NO_COLOR=1'
        The output should include 'make:smoke'
        The output should include 'Release readiness checks passed.'
        The status should be successful
    End

    It 'stops on syntax failure'
        When call mdtk_release_run syntax
        The output should include 'make:syntax'
        The output should not include 'shellspec:'
        The status should equal 11
    End

    It 'stops on the normal test-suite failure'
        When call mdtk_release_run normal
        The output should include 'shellspec:NO_COLOR=0'
        The output should not include 'shellspec:NO_COLOR=1'
        The status should equal 12
    End

    It 'stops on the NO_COLOR test-suite failure'
        When call mdtk_release_run no_color
        The output should include 'shellspec:NO_COLOR=1'
        The output should not include 'make:smoke'
        The status should equal 13
    End

    It 'stops on Smoke failure'
        When call mdtk_release_run smoke
        The output should include 'make:smoke'
        The output should not include 'Release readiness checks passed.'
        The status should equal 11
    End

    It 'fails when an unfinished runtime marker is found'
        export NO_COLOR=1
        When call mdtk_release_run markers
        The output should include 'Checking active runtime files for unfinished markers.'
        The error should include 'Unfinished runtime markers found:'
        The error should include 'src/fake.zsh:1:TODO'
        The status should be failure
    End

    It 'propagates a runtime scan execution failure'
        When call mdtk_release_run git_error
        The output should include 'Checking active runtime files for unfinished markers.'
        The error should include 'Could not scan runtime files.'
        The status should equal 14
    End

    It 'contains no network command'
        When run grep -E 'curl|wget|gh |git push|git fetch' "$MDTK_RELEASE_SCRIPT"
        The output should be blank
        The status should be failure
    End
End
