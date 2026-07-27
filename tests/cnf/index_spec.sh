# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/index_spec.sh
# Purpose: Tests for the Command Index module (Issue #009).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/cnf/index.zsh. brew is mocked with a function
#   override. Covers build, lookup hit/miss, empty, rebuild, path,
#   and brew-missing. Isolated XDG_CACHE_HOME per example.
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
    mkdir -p "${_MDTK_INDEX_TMP}/mdtk"
}

Describe 'mdtk index'
    Before 'mdtk_index_setup'
    BeforeEach 'unfunction brew 2>/dev/null || true'

    Describe 'build + lookup'
        It 'builds an index from brew and looks up by formula name'
            brew() {
                if [[ "$1" == "list" ]]; then echo "ripgrep"
                elif [[ "$1" == "info" ]]; then
                    echo "{\"name\":\"ripgrep\",\"aliases\":[\"rg\"]}"
                fi
            }
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup ripgrep
            The output should equal "ripgrep"
            The status should be successful
        End
        It 'looks up a command via its alias'
            brew() {
                if [[ "$1" == "list" ]]; then echo "ripgrep"
                elif [[ "$1" == "info" ]]; then
                    echo "{\"name\":\"ripgrep\",\"aliases\":[\"rg\",\"rga\"]}"
                fi
            }
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup rg
            The output should equal "ripgrep"
            The status should be successful
        End
        It 'returns 1 for a command not in the index'
            brew() {
                if [[ "$1" == "list" ]]; then echo "ripgrep"
                elif [[ "$1" == "info" ]]; then
                    echo "{\"name\":\"ripgrep\",\"aliases\":[\"rg\"]}"
                fi
            }
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup nope
            The output should be blank
            The status should be failure
        End
    End

    Describe 'rebuild'
        It 'replaces the index on rebuild'
            brew() {
                if [[ "$1" == "list" ]]; then echo "ripgrep"
                elif [[ "$1" == "info" ]]; then
                    echo "{\"name\":\"ripgrep\",\"aliases\":[\"rg\"]}"
                fi
            }
            mdtk_dispatch index build >/dev/null
            # Rebuild with a different formula set.
            brew() {
                if [[ "$1" == "list" ]]; then echo "fd"
                elif [[ "$1" == "info" ]]; then
                    echo "{\"name\":\"fd\",\"aliases\":[\"fdf\"]}"
                fi
            }
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup ripgrep
            The status should be failure
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
    End

    Describe 'path'
        It 'prints the index file path'
            When call mdtk_dispatch index path
            The output should include "command_index"
            The status should be successful
        End
    End
End
