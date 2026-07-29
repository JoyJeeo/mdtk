# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/index_spec.sh
# Purpose: Tests for the full Homebrew command index (Issues #009 and #033).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/cnf/index.zsh. Homebrew's complete executable metadata is
#   isolated and brew is mocked. Covers full build, lookup, malformed/missing
#   data, atomic preservation, Unicode, empty, rebuild, and a large index.
#
# Run
#   make test
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/dispatcher.zsh"

_MDTK_INDEX_TMP="$(mktemp -d)"
export XDG_CACHE_HOME="${_MDTK_INDEX_TMP}"

mdtk_index_setup() {
    rm -rf "${_MDTK_INDEX_TMP}/mdtk"
    rm -rf "${_MDTK_INDEX_TMP}/brew-cache"
    mkdir -p "${_MDTK_INDEX_TMP}/mdtk"
    mkdir -p "${_MDTK_INDEX_TMP}/brew-cache/api/internal"
}

_mdtk_index_mock_brew() {
    if [[ "$1" == "--cache" ]]; then
        echo "${_MDTK_INDEX_TMP}/brew-cache"
    elif [[ "$1" == "which-formula" ]]; then
        return 1
    fi
}

_mdtk_index_write_metadata() {
    printf '%s\n' "$@" > "${_MDTK_INDEX_TMP}/brew-cache/api/internal/executables.txt"
}

_mdtk_index_write_large_metadata() {
    local file="${_MDTK_INDEX_TMP}/brew-cache/api/internal/executables.txt"
    local i
    : > "$file"
    for i in {1..5000}; do
        echo "formula${i}(1.0):command${i} helper${i}" >> "$file"
    done
}

Describe 'mdtk index'
    Before 'mdtk_index_setup'
    BeforeEach 'unfunction brew 2>/dev/null || true'

    Describe 'build + lookup'
        It 'builds commands for formulae that are not installed'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata \
                'ripgrep(14.1.1):rg ripgrep' \
                'fd(10.2.0):fd fdfind'
            When call mdtk_dispatch index build
            The output should be blank
            The status should be successful
            The path "${_MDTK_INDEX_TMP}/mdtk/command_index" should be file
            The contents of file "${_MDTK_INDEX_TMP}/mdtk/command_index" should include "rg=ripgrep"
            The contents of file "${_MDTK_INDEX_TMP}/mdtk/command_index" should include "fdfind=fd"
        End
        It 'builds an index from brew and looks up by formula name'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata 'ripgrep(14.1.1):rg ripgrep'
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup ripgrep
            The output should equal "ripgrep"
            The status should be successful
        End
        It 'looks up a command via its alias'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata 'ripgrep(14.1.1):rg rga ripgrep'
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup rg
            The output should equal "ripgrep"
            The status should be successful
        End
        It 'returns 1 for a command not in the index'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata 'ripgrep(14.1.1):rg ripgrep'
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup nope
            The output should be blank
            The status should be failure
        End
        It 'preserves a Unicode executable name'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata 'unicode-tool(1.0):工具 unicode-tool'
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup 工具
            The output should equal "unicode-tool"
            The status should be successful
        End
        It 'preserves executable names containing a backslash'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata 'slash-tool(1.0):a\b slash-tool'
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup 'a\b'
            The output should equal "slash-tool"
            The status should be successful
        End
    End

    Describe 'rebuild'
        It 'replaces the index on rebuild'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata 'ripgrep(14.1.1):rg ripgrep'
            mdtk_dispatch index build >/dev/null
            _mdtk_index_write_metadata 'fd(10.2.0):fd fdfind'
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup ripgrep
            The status should be failure
        End
        It 'keeps the previous index when refreshed metadata is malformed'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata 'ripgrep(14.1.1):rg ripgrep'
            mdtk_dispatch index build >/dev/null
            _mdtk_index_write_metadata 'not valid metadata'
            mdtk_dispatch index build >/dev/null 2>&1 || true
            When call mdtk_dispatch index lookup rg
            The output should equal "ripgrep"
            The status should be successful
        End
    End

    Describe 'edge / errors'
        It 'returns 1 when no index has been built'
            When call mdtk_dispatch index lookup rg
            The status should be failure
        End
        It 'returns 1 and prints usage when lookup has no command'
            When call mdtk_dispatch index lookup ""
            The output should include "Usage:"
            The status should be failure
        End
        It 'returns 1 when brew is missing'
            export PATH="/usr/bin:/bin"
            When call mdtk_dispatch index build
            The status should be failure
            The error should include "Homebrew is not installed"
        End
        It 'returns 1 when complete executable metadata is missing'
            brew() { _mdtk_index_mock_brew "$@"; }
            When call mdtk_dispatch index build
            The status should be failure
            The error should include "metadata is unavailable"
        End
        It 'builds and queries a large complete index'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_large_metadata
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup helper5000
            The output should equal "formula5000"
            The status should be successful
        End
    End

    Describe 'path'
        It 'prints the index file path'
            When call mdtk_dispatch index path
            The output should include "command_index"
            The status should be successful
        End
    End
End
