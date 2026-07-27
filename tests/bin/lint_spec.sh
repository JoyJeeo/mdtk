# shellcheck shell=sh
# ============================================================
# File:    tests/bin/lint_spec.sh
# Purpose: Regression checks for the repository lint command.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   Runs the contributor lint entry point and verifies that comments in
#   zsh sources are not accidentally parsed as malformed ShellCheck
#   directives. ShellCheck's expected zsh-in-sh-mode findings remain
#   advisory; `make lint` itself must succeed.
#
# Run
#   make testone FILE=tests/bin/lint_spec.sh
# ============================================================

Describe 'make lint'
    It 'contains no malformed ShellCheck directives'
        When run make lint
        The status should be successful
        The output should not include "Couldn't parse this shellcheck directive"
        The output should not include "Expected '=' after directive key"
    End
End
