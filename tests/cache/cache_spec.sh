# shellcheck shell=sh
# ============================================================
# File:    tests/cache/cache_spec.sh
# Purpose: Tests for the Cache module (Issue #004).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/cache/cache.zsh. Each example runs against an
#   isolated XDG_CACHE_HOME. Covers get/set round-trip, missing,
#   overwrite, clean, list, bad name, empty value, large input
#   (.ai/TESTING.md).
#
# Run
#   make test
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/utils/path.zsh"
. "${MDTK_ROOT}/src/cache/cache.zsh"

_MDTK_CACHE_TMP="$(mktemp -d)"
export XDG_CACHE_HOME="${_MDTK_CACHE_TMP}"

mdtk_cache_setup() {
    rm -rf "${_MDTK_CACHE_TMP}/mdtk"
    mkdir -p "${_MDTK_CACHE_TMP}/mdtk"
}

Describe 'mdtk cache'
    Before 'mdtk_cache_setup'

    Describe 'get / set round-trip'
        It 'returns 1 and prints nothing for a missing entry'
            When call mdtk_cache_get "nope"
            The output should be blank
            The status should be failure
        End
        It 'stores and returns a value'
            mdtk_cache_set "k" "v" >/dev/null
            When call mdtk_cache_get "k"
            The output should equal "v"
            The status should be successful
        End
        It 'stores multi-line content'
            mdtk_cache_set "k" $'line1\nline2' >/dev/null
            When call mdtk_cache_get "k"
            The output should include "line1"
            The output should include "line2"
            The status should be successful
        End
    End

    Describe 'overwrite'
        It 'replaces an existing value'
            mdtk_cache_set "k" "v1" >/dev/null
            mdtk_cache_set "k" "v2" >/dev/null
            When call mdtk_cache_get "k"
            The output should equal "v2"
            The status should be successful
        End
    End

    Describe 'edge / empty input'
        It 'accepts an empty value'
            mdtk_cache_set "k" "" >/dev/null
            When call mdtk_cache_get "k"
            The output should be blank
            The status should be successful
        End
        It 'rejects an invalid name'
            When call mdtk_cache_set "../bad" "x"
            The status should be failure
        End
        It 'rejects an empty name'
            When call mdtk_cache_set "" "x"
            The status should be failure
        End
    End

    Describe 'large input'
        It 'stores a large value and reads it back'
            _big() { yes "x" | head -100 | tr "\n" " "; }
            _big > /dev/null
            mdtk_cache_set "big" "$(_big)" >/dev/null
            When call mdtk_cache_get "big"
            The output should include "x"
            The status should be successful
        End
    End

    Describe 'clean / list'
        It 'lists cache entry names'
            mdtk_cache_set "a" "1" >/dev/null
            mdtk_cache_set "b" "2" >/dev/null
            When call mdtk_cache_dispatch list
            The output should include "a"
            The output should include "b"
            The status should be successful
        End
        It 'removes one entry with clean <name>'
            mdtk_cache_set "a" "1" >/dev/null
            mdtk_cache_clean "a" >/dev/null
            When call mdtk_cache_get "a"
            The status should be failure
        End
        It 'removes all entries with clean (no name)'
            mdtk_cache_set "a" "1" >/dev/null
            mdtk_cache_set "b" "2" >/dev/null
            mdtk_cache_clean >/dev/null
            When call mdtk_cache_dispatch list
            The output should be blank
            The status should be successful
        End
    End

    Describe 'CLI (mdtk_cache_dispatch)'
        It 'sets and gets via the CLI'
            mdtk_cache_dispatch set snap "data" >/dev/null
            When call mdtk_cache_dispatch get snap
            The output should equal "data"
            The status should be successful
        End
        It 'path prints the cache dir'
            When call mdtk_cache_dispatch path
            The output should include "mdtk"
            The status should be successful
        End
        It 'usage error when get has no name'
            When call mdtk_cache_dispatch get
            The status should be failure
            The output should include "Usage:"
        End
        It 'uses an aligned error for an unknown subcommand'
            export NO_COLOR=1
            When call mdtk_cache_dispatch bogus
            The error should include '[ERROR]   Unknown cache subcommand: bogus'
            The output should include 'Usage:'
            The status should be failure
        End
    End
End
