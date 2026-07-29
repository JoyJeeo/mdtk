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
#   short-command fallback guards, not-found, pasted non-command text, empty,
#   brew-missing, and --help. Isolated XDG_CACHE_HOME.
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
    mdtk_index_build >/dev/null
}

_mdtk_cnf_dispatch_oversized_text() {
    local text=""
    local i
    for i in {1..600}; do
        text="${text}x"
    done
    mdtk_cnf_dispatch "model" "$text"
}

_mdtk_cnf_dispatch_oversized_command() {
    local cmd=""
    local i
    for i in {1..256}; do
        cmd="${cmd}x"
    done
    mdtk_cnf_dispatch "$cmd"
}

_mdtk_cnf_hook_forward_all_fields() {
    local bin_dir="${_MDTK_CNF_TMP}/hook-bin"
    rm -rf "$bin_dir"
    mkdir -p "$bin_dir"
    cat > "${bin_dir}/mdtk" <<'EOF'
#!/usr/bin/env zsh
printf '<%s>\n' "$@"
EOF
    chmod +x "${bin_dir}/mdtk"
    export PATH="${bin_dir}:/usr/bin:/bin"
    rehash
    unfunction command_not_found_handler 2>/dev/null || true
    source "${MDTK_ROOT}/scripts/mdtk.zsh"
    command_not_found_handler "fakecmd" "--hidden" "中文 文件.txt"
}

Describe 'mdtk cnf'
    Before 'mdtk_cnf_setup'
    BeforeEach 'unfunction brew 2>/dev/null || true'

    Describe 'lookup'
        It 'ignores a complete pasted numeric heading without calling Homebrew'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch "4.1" "模型使用要求"
            The output should be blank
            The status should be successful
        End
        It 'ignores a pasted list field without calling Homebrew'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch "●" "必须包含学习方法" "至少一种端到端方法"
            The output should be blank
            The status should be successful
        End
        It 'ignores a title-like natural-language field'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch "Model" "usage" "requirements"
            The output should be blank
            The status should be successful
        End
        It 'ignores a lowercase three-field heading'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch "model" "usage" "requirements"
            The output should be blank
            The status should be successful
        End
        It 'ignores long plain prose without command-line signals'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch "model" "usage" "requirements" "for" "training"
            The output should be blank
            The status should be successful
        End
        It 'ignores an oversized pasted field'
            brew() { echo "brew-was-called"; }
            When call _mdtk_cnf_dispatch_oversized_text
            The output should be blank
            The status should be successful
        End
        It 'ignores an oversized single token'
            brew() { echo "brew-was-called"; }
            When call _mdtk_cnf_dispatch_oversized_command
            The output should be blank
            The status should be successful
        End
        It 'rejects a leading option token before Homebrew'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch "--formula"
            The output should be blank
            The status should be successful
        End
        It 'keeps a punctuated executable name searchable'
            brew() {
                if [[ "$1" == "info" ]]; then
                    echo '{"name":"python3.13","aliases":[]}'
                fi
            }
            When call mdtk_cnf_dispatch "python3.13"
            The output should include "Found:"
            The output should include "python3.13"
            The status should be successful
        End
        It 'keeps options and CJK arguments searchable'
            brew() {
                if [[ "$1" == "info" ]]; then
                    echo '{"name":"bat","aliases":[]}'
                fi
            }
            When call mdtk_cnf_dispatch "bat" "--hidden" "中文 文件.txt"
            The output should include "Found:"
            The output should include "bat"
            The status should be successful
        End
        It 'keeps a single plain argument searchable'
            brew() {
                if [[ "$1" == "info" ]]; then
                    echo '{"name":"bat","aliases":[]}'
                fi
            }
            When call mdtk_cnf_dispatch "bat" "pattern"
            The output should include "Found:"
            The status should be successful
        End
        It 'recognizes path and assignment fields as command-shaped'
            When call _mdtk_cnf_input_is_searchable "tool" "./中文 文件" "MODE=fast"
            The status should be successful
        End
        It 'finds a command via the index'
            _mdtk_cnf_build_index
            When call mdtk_cnf_dispatch rg
            The output should include "Found:"
            The output should include "ripgrep"
            The output should include "brew install"
            The status should be successful
        End
        It 'falls back to the backend when not in the index'
            # No index built; brew provides the three-character boundary.
            brew() {
                if [[ "$1" == "info" ]]; then
                    echo "{\"name\":\"bat\",\"aliases\":[]}"
                fi
            }
            When call mdtk_cnf_dispatch bat
            The output should include "Found:"
            The output should include "bat"
            The status should be successful
        End
        It 'skips Homebrew fallback for a two-character index miss'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch ip
            The output should include 'Skipped automatic Homebrew search'
            The output should include 'mdtk search ip'
            The output should not include 'brew-was-called'
            The status should be successful
        End
        It 'skips Homebrew fallback for a one-character index miss'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch x
            The output should include 'Skipped automatic Homebrew search'
            The output should not include 'brew-was-called'
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
            When call mdtk_cnf_dispatch rgg
            The status should be failure
            The output should include "Homebrew is not installed"
        End
        It 'handles a short miss without requiring Homebrew'
            export PATH="/usr/bin:/bin"
            When call mdtk_cnf_dispatch ip
            The output should include 'Skipped automatic Homebrew search'
            The status should be successful
        End
    End

    Describe 'help'
        It 'prints usage on --help'
            When call mdtk_cnf_dispatch "--help"
            The output should include "Usage:"
            The status should be successful
        End
    End

    Describe 'shell hook'
        It 'forwards every original field to CNF'
            When call _mdtk_cnf_hook_forward_all_fields
            The output should include '<cnf>'
            The output should include '<fakecmd>'
            The output should include '<--hidden>'
            The output should include '<中文 文件.txt>'
            The status should be successful
        End
    End
End
