# shellcheck shell=sh
# ============================================================
# File:    tests/backends/cargo_spec.sh
# Purpose: Behavior tests for the Cargo backend (Issue #065).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Mocks Cargo to cover availability, search parsing, exact resolution,
#   installation, failures, empty/Unicode/large input, and injection safety.
#
# Run
#   make testone FILE=tests/backends/cargo_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/backends/cargo.zsh"
_MDTK_CARGO_TMP="$(mktemp -d)"

# Description: Reset Cargo mocks and scratch state.
# Parameters: none. Return: 0.
# Example: mdtk_cargo_setup
mdtk_cargo_setup() {
    unfunction cargo 2>/dev/null || true
    rm -rf -- "${_MDTK_CARGO_TMP}"
    mkdir -p "${_MDTK_CARGO_TMP}/empty"
}

# Description: Search with a 2,000-character query.
# Parameters: none. Return: backend status.
# Example: mdtk_cargo_large_query
mdtk_cargo_large_query() {
    local query="${(l:2000::x:)}"
    cargo() {
        [[ ${#6} == 2000 ]] || return 9
        print -r -- 'large-crate = "1.0.0" # large'
    }
    mdtk_backend_cargo_search "$query"
}

Describe 'cargo backend'
    BeforeEach 'mdtk_cargo_setup'

    It 'detects a Cargo function mock'
        cargo() { :; }
        When call mdtk_backend_cargo_available
        The status should be successful
    End

    It 'reports Cargo unavailable'
        export PATH="${_MDTK_CARGO_TMP}/empty"
        When call mdtk_backend_cargo_available
        The status should be failure
    End

    It 'prints validated search results one per line'
        cargo() { print -r -- $'ripgrep = "14.1.0" # fast\nripgrep_all = "1.0" # more\nmalformed'; }
        When call mdtk_backend_cargo_search ripgrep
        The output should equal $'ripgrep\nripgrep_all'
        The status should be successful
    End

    It 'passes Unicode search input unchanged'
        cargo() { [[ "$6" == '工具' ]] || return 9; print -r -- 'tool = "1" # x'; }
        When call mdtk_backend_cargo_search '工具'
        The output should equal 'tool'
        The status should be successful
    End

    It 'passes large search input unchanged'
        When call mdtk_cargo_large_query
        The output should equal 'large-crate'
        The status should be successful
    End

    It 'rejects empty search input'
        cargo() { :; }
        When call mdtk_backend_cargo_search ''
        The status should be failure
    End

    It 'propagates search failure'
        cargo() { return 8; }
        When call mdtk_backend_cargo_search absent
        The status should be failure
    End

    It 'resolves only an exact same-name crate'
        cargo() { print -r -- $'ripgrep-extra = "1" # x\nripgrep = "14" # x'; }
        When call mdtk_backend_cargo_provides ripgrep
        The output should equal 'ripgrep'
        The status should be successful
    End

    It 'rejects a non-exact command mapping'
        cargo() { print -r -- 'ripgrep-extra = "1" # x'; }
        When call mdtk_backend_cargo_provides ripgrep
        The output should be blank
        The status should be failure
    End

    It 'rejects empty command resolution input'
        cargo() { :; }
        When call mdtk_backend_cargo_provides ''
        The status should be failure
    End

    It 'delegates installation with one crate argument'
        cargo() { print -r -- "$1|$2"; }
        When call mdtk_backend_cargo_install 'two words'
        The output should equal 'install|two words'
        The status should be successful
    End

    It 'does not evaluate installation input'
        cargo() { print -r -- "$2"; }
        When call mdtk_backend_cargo_install '$(touch cargo-unsafe)'
        The output should equal '$(touch cargo-unsafe)'
        The path "${SHELLSPEC_PROJECT_ROOT}/cargo-unsafe" should not be exist
        The status should be successful
    End

    It 'propagates installation failure'
        cargo() { return 7; }
        When call mdtk_backend_cargo_install crate
        The status should equal 7
    End

    It 'rejects empty installation input'
        cargo() { :; }
        When call mdtk_backend_cargo_install ''
        The status should be failure
    End
End
