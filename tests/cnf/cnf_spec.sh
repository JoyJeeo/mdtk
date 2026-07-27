# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/cnf_spec.sh
# Purpose: Tests for the command-not-found handler (Issue #010).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/cnf/cnf.zsh. brew is mocked; a prebuilt index is
#   set up where needed. Covers index hit, backend fallback,
#   not-found, empty, brew-missing, --help. Isolated XDG_CACHE_HOME.
#
# Run
#   make test
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/cnf/cnf.zsh"

_MDTK_CNF_TMP="$(mktemp -d)"
export XDG_CACHE_HOME="${_MDTK_CNF_TMP}"

mdtk_cnf_setup() {
    rm -rf "${_MDTK_CNF_TMP}/mdtk"
    mkdir -p "${_MDTK_CNF_TMP}/mdtk"
}

# Build a prebuilt index via the index module, using a mocked brew.
_mdtk_cnf_build_index() {
    brew() {
        if [[ "$1" == "list" ]]; then echo "ripgrep"
        elif [[ "$1" == "info" ]]; then
            echo "{\"name\":\"ripgrep\",\"aliases\":[\"rg\"]}"
        fi
    }
    mdtk_index_dispatch build >/dev/null
}

Describe 'mdtk cnf'
    Before 'mdtk_cnf_setup'
    BeforeEach 'unfunction brew 2>/dev/null || true'

    Describe 'lookup'
        It 'finds a command via the index'
            _mdtk_cnf_build_index
            When call mdtk_cnf_dispatch rg
            The output should include "Found:"
            The output should include "ripgrep"
            The output should include "brew install"
            The status should be successful
        End
        It 'falls back to the backend when not in the index'
            # No index built; brew provides "fd".
            brew() {
                if [[ "$1" == "info" ]]; then
                    echo "{\"name\":\"fd\",\"aliases\":[\"fdf\"]}"
                fi
            }
            When call mdtk_cnf_dispatch fd
            The output should include "Found:"
            The output should include "fd"
            The status should be successful
        End
        It 'prints a friendly not-found message when nothing matches'
            brew() {
                if [[ "$1" == "info" ]]; then echo "{}"; fi
            }
            When call mdtk_cnf_dispatch definitely-not-real
            The output should include "No Homebrew formula found"
            The status should be successful
        End
    End

    Describe 'errors'
        It 'returns 1 and prints usage when no command'
            When call mdtk_cnf_dispatch ""
            The output should include "Usage:"
            The status should be failure
        End
        It 'returns 1 when brew is missing and no index'
            export PATH="/usr/bin:/bin"
            When call mdtk_cnf_dispatch rg
            The status should be failure
            The output should include "Homebrew is not installed"
        End
    End

    Describe 'help'
        It 'prints usage on --help'
            When call mdtk_cnf_dispatch "--help"
            The output should include "Usage:"
            The status should be successful
        End
    End
End
