# shellcheck shell=sh
# ============================================================
# File:    tests/backends/npm_spec.sh
# Purpose: Behavior tests for the npm backend (Issue #067).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Mocks npm to cover availability, parseable search, bin metadata resolution,
#   global installation, failures, empty/Unicode/large input, and injection.
#
# Run
#   make testone FILE=tests/backends/npm_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/backends/npm.zsh"
_MDTK_NPM_TMP="$(mktemp -d)"

# Description: Reset npm mocks and scratch state.
# Parameters: none. Return: 0.
# Example: mdtk_npm_setup
mdtk_npm_setup() {
    unfunction npm 2>/dev/null || true
    rm -rf -- "${_MDTK_NPM_TMP}"
    mkdir -p "${_MDTK_NPM_TMP}/empty"
}

# Description: Search with a 2,000-character query.
# Parameters: none. Return: backend status.
# Example: mdtk_npm_large_query
mdtk_npm_large_query() {
    local query="${(l:2000::x:)}"
    npm() {
        [[ ${#2} == 2000 ]] || return 9
        print -r -- $'large-package\tdescription\tuser'
    }
    mdtk_backend_npm_search "$query"
}

Describe 'npm backend'
    BeforeEach 'mdtk_npm_setup'

    It 'detects an npm function mock'
        npm() { :; }
        When call mdtk_backend_npm_available
        The status should be successful
    End

    It 'reports npm unavailable'
        export PATH="${_MDTK_NPM_TMP}/empty"
        When call mdtk_backend_npm_available
        The status should be failure
    End

    It 'parses unique package names from tab-separated search output'
        npm() { print -r -- $'typescript\tdesc\tuser\n@scope/tool\tdesc\tuser\ntypescript\tagain\tuser\nbad name\tdesc\tuser'; }
        When call mdtk_backend_npm_search type
        The output should equal $'typescript\n@scope/tool'
        The status should be successful
    End

    It 'passes Unicode search input unchanged'
        npm() { [[ "$2" == '工具' ]] || return 9; print -r -- $'tool\tdesc'; }
        When call mdtk_backend_npm_search '工具'
        The output should equal 'tool'
        The status should be successful
    End

    It 'passes large search input unchanged'
        When call mdtk_npm_large_query
        The output should equal 'large-package'
        The status should be successful
    End

    It 'rejects empty search input'
        npm() { :; }
        When call mdtk_backend_npm_search ''
        The status should be failure
    End

    It 'propagates search failure'
        npm() { return 8; }
        When call mdtk_backend_npm_search absent
        The status should be failure
    End

    It 'resolves exact same-name bin metadata'
        npm() {
            [[ "$1|$2|$3|$4" == 'view|typescript|bin.typescript|--json' ]] || return 9
            print -r -- '"./bin/tsc"'
        }
        When call mdtk_backend_npm_provides typescript
        The output should equal 'typescript'
        The status should be successful
    End

    It 'rejects null bin metadata'
        npm() { print -r -- 'null'; }
        When call mdtk_backend_npm_provides library-only
        The output should be blank
        The status should be failure
    End

    It 'rejects empty command-resolution input'
        npm() { :; }
        When call mdtk_backend_npm_provides ''
        The status should be failure
    End

    It 'rejects unsafe command metadata paths before npm'
        npm() { print -r -- 'called'; }
        When call mdtk_backend_npm_provides '../tool'
        The output should be blank
        The status should be failure
    End

    It 'delegates global installation with one package argument'
        npm() { print -r -- "$1|$2|$3"; }
        When call mdtk_backend_npm_install '@scope/two words'
        The output should equal 'install|--global|@scope/two words'
        The status should be successful
    End

    It 'does not evaluate installation input'
        npm() { print -r -- "$3"; }
        When call mdtk_backend_npm_install '$(touch npm-unsafe)'
        The output should equal '$(touch npm-unsafe)'
        The path "${SHELLSPEC_PROJECT_ROOT}/npm-unsafe" should not be exist
        The status should be successful
    End

    It 'propagates installation failure'
        npm() { return 7; }
        When call mdtk_backend_npm_install package
        The status should equal 7
    End

    It 'rejects empty installation input'
        npm() { :; }
        When call mdtk_backend_npm_install ''
        The status should be failure
    End
End
