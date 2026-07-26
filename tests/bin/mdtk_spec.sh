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
        The output should include 'cnf'
        The status should be successful
        End
    End

    Describe 'logger'
        It 'emits an INFO line via the CLI'
        When call "$MDTK_BIN" logger --info "hello"
        The output should include '[INFO]'
        The output should include 'hello'
        The status should be successful
        End
    End

    Describe 'cnf route'
        It 'routes the cnf subcommand to the cnf module'
        When call "$MDTK_BIN" cnf some-missing-command
        The output should include 'command-not-found handler'
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
