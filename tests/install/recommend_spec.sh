# shellcheck shell=sh
# ============================================================
# File:    tests/install/recommend_spec.sh
# Purpose: Tests for colored install recommendations (Issue #047).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Tests the recommendation module with mocked Homebrew functions. Covers
#   found, missing, unavailable, empty, Unicode, large, help, and NO_COLOR.
#
# Run
#   make testone FILE=tests/install/recommend_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/install/install.zsh"

mdtk_install_recommend_setup() {
    mdtk_backend_homebrew_available() { return 0; }
    mdtk_backend_homebrew_provides() {
        [[ "$1" == "rg" ]] && echo "ripgrep"
        return 0
    }
}

_mdtk_install_large_recommendation() {
    local command="${(l:4096::x:)}"
    mdtk_install_recommend "$command"
}

Describe 'mdtk install recommendation'
    BeforeEach 'mdtk_install_recommend_setup; unset NO_COLOR; unset MDTK_NO_COLOR'

    It 'prints aligned success and info labels for a match'
        export NO_COLOR=1
        When call mdtk_install_recommend "rg"
        The output should include '[SUCCESS] Found:'
        The output should include '[INFO]    Run: brew install ripgrep'
        The status should be successful
    End

    It 'prints warning and info labels for a miss'
        export NO_COLOR=1
        When call mdtk_install_recommend "missing"
        The output should include '[WARNING] No Homebrew formula found'
        The output should include '[INFO]    Try: mdtk search missing'
        The status should be successful
    End

    It 'writes a colored error to stderr when Homebrew is unavailable'
        mdtk_backend_homebrew_available() { return 1; }
        When call mdtk_install_recommend "rg"
        The error should include $'\033['
        The error should include '[ERROR]'
        The status should be failure
    End

    It 'rejects an empty command without output'
        When call mdtk_install_recommend ""
        The output should be blank
        The status should be failure
    End

    It 'preserves Unicode in miss guidance'
        export NO_COLOR=1
        When call mdtk_install_recommend "工具"
        The output should include '工具'
        The status should be successful
    End

    It 'preserves a large command in miss guidance'
        export NO_COLOR=1
        When call _mdtk_install_large_recommendation
        The output should include "${(l:256::x:)}"
        The status should be successful
    End

    It 'prints help without consulting Homebrew'
        mdtk_backend_homebrew_available() { echo "brew-called"; return 1; }
        When call mdtk_install_dispatch --help
        The output should include 'Usage: mdtk install'
        The output should not include 'brew-called'
        The status should be successful
    End
End
