# shellcheck shell=sh
# ============================================================
# File:    tests/search/search_spec.sh
# Purpose: Behavior tests for multi-backend Search (Issue #068).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Mocks every external package manager and covers default compatibility,
#   explicit routing, parsing, unavailable/failing/unknown backends, CLI option
#   errors, empty/Unicode/large queries, and no-result behavior.
#
# Run
#   make testone FILE=tests/search/search_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/search/search.zsh"
_MDTK_SEARCH_TMP="$(mktemp -d)"

# Description: Reset external-tool mocks and mode variables.
# Parameters: none. Return: 0.
# Example: mdtk_search_setup
mdtk_search_setup() {
    unfunction brew pip3 pip cargo conda npm 2>/dev/null || true
    rm -rf -- "${_MDTK_SEARCH_TMP}"
    mkdir -p "${_MDTK_SEARCH_TMP}/empty"
    unset NO_COLOR
}

# Description: Route a 2,000-character query through the pip backend.
# Parameters: none. Return: Search dispatch status.
# Example: mdtk_search_large_query
mdtk_search_large_query() {
    local query="${(l:2000::x:)}"
    pip3() {
        [[ ${#3} == 2000 ]] || return 9
        print -r -- 'large-package (1.0.0)'
    }
    mdtk_search_dispatch --backend pip "$query"
}

Describe 'mdtk search'
    BeforeEach 'mdtk_search_setup'

    It 'preserves Homebrew as the default backend'
        brew() { print -r -- $'ripgrep\nripgrep-all'; }
        When call mdtk_search_dispatch ripgrep
        The output should equal $'ripgrep\nripgrep-all'
        The status should be successful
    End

    It 'routes explicitly to Homebrew'
        brew() { print -r -- 'homebrew-result'; }
        When call mdtk_search_dispatch --backend homebrew query
        The output should equal 'homebrew-result'
        The status should be successful
    End

    It 'routes to pip'
        pip3() { print -r -- 'HTTPie (3.2.4)'; }
        When call mdtk_search_dispatch --backend pip httpie
        The output should equal 'HTTPie'
        The status should be successful
    End

    It 'routes to cargo'
        cargo() { print -r -- 'ripgrep = "14" # fast'; }
        When call mdtk_search_dispatch --backend cargo ripgrep
        The output should equal 'ripgrep'
        The status should be successful
    End

    It 'routes to conda'
        conda() { print -r -- 'httpie  3  py  defaults'; }
        When call mdtk_search_dispatch --backend conda httpie
        The output should equal 'httpie'
        The status should be successful
    End

    It 'routes to npm'
        npm() { print -r -- $'typescript\tdescription'; }
        When call mdtk_search_dispatch --backend npm typescript
        The output should equal 'typescript'
        The status should be successful
    End

    It 'prints no output for an empty successful result'
        brew() { :; }
        When call mdtk_search_dispatch absent
        The output should be blank
        The status should be successful
    End

    It 'passes Unicode query input unchanged'
        npm() { [[ "$2" == '工具' ]] || return 9; print -r -- $'tool\tdesc'; }
        When call mdtk_search_dispatch --backend npm '工具'
        The output should equal 'tool'
        The status should be successful
    End

    It 'passes large query input unchanged'
        When call mdtk_search_large_query
        The output should equal 'large-package'
        The status should be successful
    End

    It 'rejects missing query input'
        When call mdtk_search_dispatch
        The output should include 'Usage:'
        The status should be failure
    End

    It 'rejects a missing backend option value'
        When call mdtk_search_dispatch --backend
        The error should include 'requires a name'
        The status should be failure
    End

    It 'rejects an unknown backend without dynamic evaluation'
        When call mdtk_search_dispatch --backend '$(touch unsafe)' query
        The error should include 'Unknown package backend'
        The path "${SHELLSPEC_PROJECT_ROOT}/unsafe" should not be exist
        The status should be failure
    End

    It 'reports an unavailable selected backend'
        export PATH="${_MDTK_SEARCH_TMP}/empty"
        When call mdtk_search_dispatch --backend cargo query
        The error should include 'Package backend is not available: cargo'
        The status should be failure
    End

    It 'preserves the Homebrew-specific unavailable error'
        export PATH="${_MDTK_SEARCH_TMP}/empty"
        export NO_COLOR=1
        When call mdtk_search_dispatch query
        The error should include '[ERROR]   Homebrew is not installed. mdtk search needs Homebrew.'
        The status should be failure
    End

    It 'propagates a selected backend search failure'
        npm() { return 8; }
        When call mdtk_search_dispatch --backend npm query
        The status should be failure
    End

    It 'rejects an unknown option'
        When call mdtk_search_dispatch --bogus query
        The error should include 'Unknown search option'
        The status should be failure
    End

    It 'rejects extra query tokens'
        brew() { :; }
        When call mdtk_search_dispatch first second
        The error should include 'Search accepts one query'
        The status should be failure
    End

    It 'prints help with the supported backend list'
        When call mdtk_search_dispatch --help
        The output should include 'homebrew'
        The output should include 'pip'
        The output should include 'cargo'
        The output should include 'conda'
        The output should include 'npm'
        The status should be successful
    End
End
