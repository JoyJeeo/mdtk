# shellcheck shell=sh
# ============================================================
# File:    tests/backends/conda_spec.sh
# Purpose: Behavior tests for the conda backend (Issue #066).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Mocks conda to cover availability, tabular parsing, exact resolution,
#   installation, failures, empty/Unicode/large input, and injection safety.
#
# Run
#   make testone FILE=tests/backends/conda_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/backends/conda.zsh"
_MDTK_CONDA_TMP="$(mktemp -d)"

# Description: Reset conda mocks and scratch state.
# Parameters: none. Return: 0.
# Example: mdtk_conda_setup
mdtk_conda_setup() {
    unfunction conda 2>/dev/null || true
    rm -rf -- "${_MDTK_CONDA_TMP}"
    mkdir -p "${_MDTK_CONDA_TMP}/empty"
}

# Description: Search with a 2,000-character query.
# Parameters: none. Return: backend status.
# Example: mdtk_conda_large_query
mdtk_conda_large_query() {
    local query="${(l:2000::x:)}"
    conda() {
        [[ ${#2} == 2000 ]] || return 9
        print -r -- 'large-package  1.0  build  channel'
    }
    mdtk_backend_conda_search "$query"
}

Describe 'conda backend'
    BeforeEach 'mdtk_conda_setup'

    It 'detects a conda function mock'
        conda() { :; }
        When call mdtk_backend_conda_available
        The status should be successful
    End

    It 'reports conda unavailable'
        export PATH="${_MDTK_CONDA_TMP}/empty"
        When call mdtk_backend_conda_available
        The status should be failure
    End

    It 'parses unique package names and ignores headers'
        conda() { print -r -- $'Loading channels: done\n# Name Version Build Channel\nhttpie  3.2  py  defaults\nhttpie  3.1  py  defaults\nhttpie-cli  1.0  py  forge'; }
        When call mdtk_backend_conda_search httpie
        The output should equal $'httpie\nhttpie-cli'
        The status should be successful
    End

    It 'returns an empty successful result for no matches'
        conda() { print -r -- 'No match found for: missing'; }
        When call mdtk_backend_conda_search missing
        The output should be blank
        The status should be successful
    End

    It 'passes Unicode search input unchanged'
        conda() { [[ "$2" == '工具' ]] || return 9; print -r -- 'tool  1  b  c'; }
        When call mdtk_backend_conda_search '工具'
        The output should equal 'tool'
        The status should be successful
    End

    It 'passes large search input unchanged'
        When call mdtk_conda_large_query
        The output should equal 'large-package'
        The status should be successful
    End

    It 'rejects empty search input'
        conda() { :; }
        When call mdtk_backend_conda_search ''
        The status should be failure
    End

    It 'propagates search failure'
        conda() { return 8; }
        When call mdtk_backend_conda_search absent
        The status should be failure
    End

    It 'resolves only an exact same-name package'
        conda() { print -r -- $'httpie-extra  1  b  c\nhttpie  3  b  c'; }
        When call mdtk_backend_conda_provides httpie
        The output should equal 'httpie'
        The status should be successful
    End

    It 'rejects a non-exact command mapping'
        conda() { print -r -- 'httpie-extra  1  b  c'; }
        When call mdtk_backend_conda_provides httpie
        The status should be failure
    End

    It 'rejects empty command-resolution input'
        conda() { :; }
        When call mdtk_backend_conda_provides ''
        The status should be failure
    End

    It 'delegates installation with one package argument'
        conda() { print -r -- "$1|$2"; }
        When call mdtk_backend_conda_install 'two words'
        The output should equal 'install|two words'
        The status should be successful
    End

    It 'does not evaluate installation input'
        conda() { print -r -- "$2"; }
        When call mdtk_backend_conda_install '$(touch conda-unsafe)'
        The output should equal '$(touch conda-unsafe)'
        The path "${SHELLSPEC_PROJECT_ROOT}/conda-unsafe" should not be exist
        The status should be successful
    End

    It 'propagates installation failure'
        conda() { return 7; }
        When call mdtk_backend_conda_install package
        The status should equal 7
    End

    It 'rejects empty installation input'
        conda() { :; }
        When call mdtk_backend_conda_install ''
        The status should be failure
    End
End
