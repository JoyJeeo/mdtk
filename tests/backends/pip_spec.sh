# shellcheck shell=sh
# ============================================================
# File:    tests/backends/pip_spec.sh
# Purpose: Behavior tests for the pip backend (Issue #064).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Mocks pip functions to cover tool selection, queries, same-name command
#   resolution, installation, failures, empty/Unicode/large input, and argument
#   injection safety without accessing PyPI or installing packages.
#
# Run
#   make testone FILE=tests/backends/pip_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/backends/pip.zsh"

_MDTK_PIP_TMP="$(mktemp -d)"

# Description: Reset pip mocks and the isolated scratch directory.
# Parameters: none. Return: 0.
# Example: mdtk_pip_setup
mdtk_pip_setup() {
    unfunction pip3 pip 2>/dev/null || true
    rm -rf -- "${_MDTK_PIP_TMP}"
    mkdir -p "${_MDTK_PIP_TMP}/empty"
}

# Description: Query with a 2,000-character package token.
# Parameters: none. Return: backend search status.
# Example: mdtk_pip_large_query
mdtk_pip_large_query() {
    local query="${(l:2000::x:)}"
    pip3() {
        (( ${#3} == 2000 )) || return 9
        print -r -- 'large-package (1.0.0)'
    }
    mdtk_backend_pip_search "$query"
}

Describe 'pip backend'
    BeforeEach 'mdtk_pip_setup'

    It 'prefers pip3 over pip'
        pip3() { print -r -- 'pip3'; }
        pip() { print -r -- 'pip'; }
        When call _mdtk_backend_pip_tool
        The output should equal 'pip3'
        The status should be successful
    End

    It 'falls back to pip'
        export PATH="${_MDTK_PIP_TMP}/empty"
        pip() { print -r -- 'pip'; }
        When call _mdtk_backend_pip_tool
        The output should equal 'pip'
        The status should be successful
    End

    It 'reports availability with a function mock'
        pip3() { :; }
        When call mdtk_backend_pip_available
        The status should be successful
    End

    It 'reports an unavailable tool'
        export PATH="${_MDTK_PIP_TMP}/empty"
        When call mdtk_backend_pip_available
        The status should be failure
    End

    It 'queries and prints the canonical package name'
        pip3() { print -r -- 'HTTPie (3.2.4)'; }
        When call mdtk_backend_pip_search httpie
        The output should equal 'HTTPie'
        The status should be successful
    End

    It 'uses exact same-name lookup for command resolution'
        pip3() { print -r -- 'black (24.4.0)'; }
        When call mdtk_backend_pip_provides black
        The output should equal 'black'
        The status should be successful
    End

    It 'passes Unicode query input as one argument'
        pip3() {
            [[ "$3" == '数据工具' ]] || return 9
            print -r -- 'data-tool (1.0.0)'
        }
        When call mdtk_backend_pip_search '数据工具'
        The output should equal 'data-tool'
        The status should be successful
    End

    It 'passes large query input without truncation'
        When call mdtk_pip_large_query
        The output should equal 'large-package'
        The status should be successful
    End

    It 'rejects empty search input'
        pip3() { return 0; }
        When call mdtk_backend_pip_search ''
        The status should be failure
    End

    It 'rejects empty command-resolution input'
        pip3() { return 0; }
        When call mdtk_backend_pip_provides ''
        The status should be failure
    End

    It 'rejects malformed pip output'
        pip3() { print -r -- 'unexpected output'; }
        When call mdtk_backend_pip_search package
        The output should be blank
        The status should be failure
    End

    It 'propagates query failure'
        pip3() { return 6; }
        When call mdtk_backend_pip_search absent
        The status should be failure
    End

    It 'delegates installation with one package argument'
        pip3() { print -r -- "$1|$2"; }
        When call mdtk_backend_pip_install 'two words'
        The output should equal 'install|two words'
        The status should be successful
    End

    It 'does not evaluate installation input'
        pip3() { print -r -- "$2"; }
        When call mdtk_backend_pip_install '$(touch pip-unsafe)'
        The output should equal '$(touch pip-unsafe)'
        The path "${SHELLSPEC_PROJECT_ROOT}/pip-unsafe" should not be exist
        The status should be successful
    End

    It 'propagates installation failure'
        pip3() { return 9; }
        When call mdtk_backend_pip_install package
        The status should equal 9
    End


    It 'rejects an empty installation package'
        pip3() { return 0; }
        When call mdtk_backend_pip_install ''
        The status should be failure
    End
End
