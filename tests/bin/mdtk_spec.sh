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

# Description: Run the smoke target with a stale fake `mdtk` first on PATH.
# Parameters: none. Return: the smoke target's exit status.
# Example: _mdtk_smoke_with_stale_path_command
_mdtk_smoke_with_stale_path_command() {
    local fake_dir
    fake_dir="$(mktemp -d)" || return 1
    printf '#!/bin/sh\necho "mdtk stale-path-version"\n' > "${fake_dir}/mdtk"
    chmod +x "${fake_dir}/mdtk"
    PATH="${fake_dir}:${PATH}" make -s smoke
    local result_code=$?
    rm -rf -- "$fake_dir"
    return "$result_code"
}

Describe 'mdtk'
    Describe 'version'
        It 'prints the version and exits 0'
        When call "$MDTK_BIN" version
        The output should equal 'mdtk 0.2.0'
        The status should be successful
        End
    End

    Describe 'smoke target'
        It 'runs the checkout entry point instead of a stale PATH command'
        When call _mdtk_smoke_with_stale_path_command
        The output should include 'mdtk 0.2.0'
        The output should not include 'stale-path-version'
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
        The output should include 'uninstall'
        The output should include 'update'
        The output should include 'plugin     Discover and run user plugins.'
        The output should not include 'not implemented'
        The status should be successful
        End
    End

    It 'routes uninstall help without changing files'
        When run "$MDTK_BIN" uninstall --help
        The status should be successful
        The output should include 'Usage: mdtk uninstall'
    End

    It 'routes update help without changing files'
        When run "$MDTK_BIN" update --help
        The status should be successful
        The output should include 'Usage: mdtk update'
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
        The output should include 'No cached Homebrew recommendation found'
        End
    End

    Describe 'unknown command'
        It 'gives a friendly message and exits non-zero'
        When call "$MDTK_BIN" bogus-command
        The output should include 'Unknown command'
        The status should be failure
        End
        It 'uses aligned labels without icons when color is disabled'
        export NO_COLOR=1
        When call "$MDTK_BIN" bogus-command
        The output should include '[ERROR]   Unknown command: bogus-command'
        The output should include "[INFO]    Run 'mdtk help'"
        The output should not include $'\033['
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
