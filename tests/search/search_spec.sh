# shellcheck shell=sh
# ============================================================
# File:    tests/search/search_spec.sh
# Purpose: Tests for the Search module (Issue #007).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/search/search.zsh. The Homebrew backend is mocked
#   via a `brew` function override (no real network). Covers query,
#   empty, no results, missing brew, help.
#
# Run
#   make test
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/search/search.zsh"

Describe 'mdtk search'
    BeforeEach 'unfunction brew 2>/dev/null || true'

    Describe 'query'
        It 'prints results one per line'
            brew() { echo "ripgrep"; echo "ripgrep-all"; }
            When call mdtk_search_dispatch "ripgrep"
            The output should include "ripgrep"
            The output should include "ripgrep-all"
            The status should be successful
        End
        It 'prints nothing when no results'
            brew() { :; }
            When call mdtk_search_dispatch "definitely-not-real"
            The output should be blank
            The status should be successful
        End
    End

    Describe 'errors'
        It 'returns 1 and prints usage when no query'
            When call mdtk_search_dispatch ""
            The output should include "Usage:"
            The status should be failure
        End
        It 'returns 1 when brew is missing'
            export PATH="/usr/bin:/bin"
            export NO_COLOR=1
            When call mdtk_search_dispatch "ripgrep"
            The status should be failure
            The error should include "[ERROR]   Homebrew is not installed"
        End
    End

    Describe 'help'
        It 'prints usage on --help'
            When call mdtk_search_dispatch "--help"
            The output should include "Usage:"
            The status should be successful
        End
    End
End
