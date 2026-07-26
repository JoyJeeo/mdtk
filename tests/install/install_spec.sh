# shellcheck shell=sh
# ============================================================
# File:    tests/install/install_spec.sh
# Purpose: Tests for the Install module (Issue #008).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/install/install.zsh. The Homebrew backend is
#   mocked via a `brew` function override. Covers a found command,
#   an unknown command, empty input, missing brew, and --help.
#
# Run
#   make test
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/install/install.zsh"

Describe 'mdtk install'
    BeforeEach 'unfunction brew 2>/dev/null || true'

    Describe 'recommend'
        It 'prints a recommendation when a formula is found'
            brew() {
                if [[ "$1" == "info" ]]; then
                    echo '[{"name":"ripgrep"}]'
                elif [[ "$1" == "search" ]]; then
                    echo "ripgrep"
                fi
            }
            When call mdtk_install_dispatch "ripgrep"
            The output should include "ripgrep"
            The output should include "brew install"
            The status should be successful
        End
        It 'prints a friendly not-found message for an unknown command'
            brew() {
                if [[ "$1" == "info" ]]; then
                    echo "Error" >&2; return 1
                elif [[ "$1" == "search" ]]; then
                    echo ""
                fi
            }
            When call mdtk_install_dispatch "definitely-not-real"
            The output should include "No Homebrew formula found"
            The status should be successful
        End
    End

    Describe 'errors'
        It 'returns 1 and prints usage when no command'
            When call mdtk_install_dispatch ""
            The output should include "Usage:"
            The status should be failure
        End
        It 'returns 1 when brew is missing'
            export PATH="/usr/bin:/bin"
            When call mdtk_install_dispatch "rg"
            The status should be failure
            The error should include "Homebrew is not installed"
        End
    End

    Describe 'help'
        It 'prints usage on --help'
            When call mdtk_install_dispatch "--help"
            The output should include "Usage:"
            The status should be successful
        End
    End
End
