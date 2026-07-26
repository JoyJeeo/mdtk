# shellcheck shell=sh
# ============================================================
# File:    tests/bin/mdtk_spec.sh
# Purpose: Smoke tests for the mdtk skeleton (infrastructure only).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   These specs only verify that the entry point, dispatcher,
#   version constant, and module stubs are wired up. They do NOT
#   test unimplemented business logic (Logger etc.) — those land
#   when their TASK.md is opened, per .ai/MASTER_PROMPT.md.
#
# Parameters
#   None (shellspec drives them).
#
# Run
#   make test   (or: shellspec)
# ============================================================

# Path to the project's entry point.
MDTK_BIN="${SHELLSPEC_PROJECT_ROOT}/bin/mdtk"

Describe 'mdtk'
    Describe 'version'
        It 'prints the version and exits 0'
        When call "$MDTK_BIN" version
        The output should include 'mdtk'
        The status should be successful
        End
    End

    Describe 'help'
        It 'lists known commands and exits 0'
        When call "$MDTK_BIN" help
        The output should include 'Available commands'
        The output should include 'version'
        The output should include 'help'
        The status should be successful
        End
    End

    Describe 'logger (stub)'
        It 'reports not implemented and exits non-zero'
        When call "$MDTK_BIN" logger
        The output should include 'not implemented yet'
        The status should be failure
        End
    End

    Describe 'unknown command'
        It 'gives a friendly message and exits non-zero'
        When call "$MDTK_BIN" bogus-command
        The output should include 'Unknown command'
        The status should be failure
        End
    End

    Describe 'no command'
        It 'falls back to help and exits non-zero'
        When call "$MDTK_BIN"
        The output should include 'Available commands'
        The status should be failure
        End
    End
End
