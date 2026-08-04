# shellcheck shell=sh
# ============================================================
# File:    tests/install/recommend_spec.sh
# Purpose: Behavior tests for multi-backend recommendations (Issue #069).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Mocks backend contracts to cover every install command, Homebrew default
#   compatibility, misses, unavailable/unknown backends, option errors, empty,
#   Unicode and large input, argument safety, help, and NO_COLOR.
#
# Run
#   make testone FILE=tests/install/recommend_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/install/install.zsh"

# Description: Reset deterministic backend contract mocks.
# Parameters: none. Return: 0.
# Example: mdtk_install_recommend_setup
mdtk_install_recommend_setup() {
    local backend
    for backend in homebrew pip cargo conda npm; do
        functions[mdtk_backend_${backend}_available]='return 0'
        functions[mdtk_backend_${backend}_provides]='return 0'
    done
    unset NO_COLOR MDTK_NO_COLOR
}

# Description: Recommend for a 4,096-character command.
# Parameters: none. Return: recommendation status.
# Example: _mdtk_install_large_recommendation
_mdtk_install_large_recommendation() {
    local command_name="${(l:4096::x:)}"
    mdtk_install_recommend "$command_name"
}

Describe 'mdtk install recommendation'
    BeforeEach 'mdtk_install_recommend_setup'

    It 'preserves the default Homebrew recommendation contract'
        mdtk_backend_homebrew_provides() { echo 'ripgrep'; }
        export NO_COLOR=1
        When call mdtk_install_dispatch rg
        The output should include '[SUCCESS] Found: the "rg" command is provided by the "ripgrep" formula.'
        The output should include '[INFO]    Run: brew install ripgrep'
        The status should be successful
    End

    It 'recommends pip installation'
        mdtk_backend_pip_provides() { echo 'httpie'; }
        When call mdtk_install_dispatch --backend pip httpie
        The output should include 'package in pip'
        The output should include 'Run: pip install httpie'
        The status should be successful
    End

    It 'recommends Cargo installation'
        mdtk_backend_cargo_provides() { echo 'ripgrep'; }
        When call mdtk_install_dispatch --backend cargo ripgrep
        The output should include 'Run: cargo install ripgrep'
        The status should be successful
    End

    It 'recommends conda installation'
        mdtk_backend_conda_provides() { echo 'httpie'; }
        When call mdtk_install_dispatch --backend conda httpie
        The output should include 'Run: conda install httpie'
        The status should be successful
    End

    It 'recommends global npm installation'
        mdtk_backend_npm_provides() { echo 'typescript'; }
        When call mdtk_install_dispatch --backend npm typescript
        The output should include 'Run: npm install --global typescript'
        The status should be successful
    End

    It 'preserves Homebrew miss guidance'
        export NO_COLOR=1
        When call mdtk_install_recommend missing
        The output should include '[WARNING] No Homebrew formula found'
        The output should include '[INFO]    Try: mdtk search missing'
        The output should not include '--backend homebrew'
        The status should be successful
    End

    It 'prints backend-specific miss guidance'
        mdtk_backend_npm_provides() { return 1; }
        When call mdtk_install_recommend missing npm
        The output should include 'No npm package found'
        The output should include 'mdtk search --backend npm missing'
        The status should be successful
    End

    It 'preserves the Homebrew-specific unavailable error'
        mdtk_backend_homebrew_available() { return 1; }
        export NO_COLOR=1
        When call mdtk_install_recommend rg
        The error should include '[ERROR]   Homebrew is not installed. mdtk install needs Homebrew.'
        The status should be failure
    End

    It 'reports an unavailable selected backend'
        mdtk_backend_cargo_available() { return 1; }
        When call mdtk_install_dispatch --backend cargo ripgrep
        The error should include 'Package backend is not available: cargo'
        The status should be failure
    End

    It 'rejects an unknown backend without evaluation'
        When call mdtk_install_dispatch --backend '$(touch unsafe)' command
        The error should include 'Unknown package backend'
        The path "${SHELLSPEC_PROJECT_ROOT}/unsafe" should not be exist
        The status should be failure
    End

    It 'rejects empty command input'
        When call mdtk_install_dispatch
        The output should include 'Usage:'
        The status should be failure
    End

    It 'rejects a missing backend option value'
        When call mdtk_install_dispatch --backend
        The error should include 'requires a name'
        The status should be failure
    End

    It 'rejects unknown options'
        When call mdtk_install_dispatch --bogus command
        The error should include 'Unknown install option'
        The status should be failure
    End

    It 'rejects extra command tokens'
        When call mdtk_install_dispatch first second
        The error should include 'Install accepts one command'
        The status should be failure
    End

    It 'preserves Unicode in miss guidance'
        When call mdtk_install_dispatch --backend conda '工具'
        The output should include '工具'
        The status should be successful
    End

    It 'preserves large command input in miss guidance'
        export NO_COLOR=1
        When call _mdtk_install_large_recommendation
        The output should include "${(l:256::x:)}"
        The status should be successful
    End

    It 'prints help without consulting backends'
        mdtk_backend_homebrew_available() { echo 'backend-called'; return 1; }
        When call mdtk_install_dispatch --help
        The output should include 'Usage: mdtk install'
        The output should not include 'backend-called'
        The status should be successful
    End
End
