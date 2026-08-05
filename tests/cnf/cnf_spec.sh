# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/cnf_spec.sh
# Purpose: Tests for command-not-found handling (Issues #010 and #078).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/cnf/cnf.zsh. Prebuilt backend indexes are isolated. Covers
#   all-match offline recommendations, input classification, empty, and help.
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

_mdtk_cnf_write_backend() {
    local backend="$1"
    shift
    mkdir -p "${_MDTK_CNF_TMP}/mdtk/index"
    printf '%s\n' "$@" | LC_ALL=C sort -u \
        > "${_MDTK_CNF_TMP}/mdtk/index/${backend}.idx"
}

_mdtk_cnf_dispatch_without_managers() {
    brew() { echo 'manager-was-called'; }
    pip() { echo 'manager-was-called'; }
    pip3() { echo 'manager-was-called'; }
    npm() { echo 'manager-was-called'; }
    cargo() { echo 'manager-was-called'; }
    conda() { echo 'manager-was-called'; }
    mdtk_cnf_dispatch tool
}

# Build a prebuilt index via the index module, using a mocked brew.
_mdtk_cnf_build_index() {
    brew() {
        if [[ "$1" == "--cache" ]]; then
            echo "${_MDTK_CNF_TMP}/brew-cache"
        elif [[ "$1" == "which-formula" ]]; then
            return 1
        fi
    }
    mkdir -p "${_MDTK_CNF_TMP}/brew-cache/api/internal"
    echo 'ripgrep(14.1.1):rg ripgrep' > \
        "${_MDTK_CNF_TMP}/brew-cache/api/internal/executables.txt"
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
            When call mdtk_cnf_dispatch "python3.13"
            The output should include "No cached package recommendation"
            The output should include "python3.13"
            The status should be successful
        End
        It 'keeps options and CJK arguments searchable'
            When call mdtk_cnf_dispatch "bat" "--hidden" "中文 文件.txt"
            The output should include "No cached package recommendation"
            The output should include "bat"
            The status should be successful
        End
        It 'keeps a single plain argument searchable'
            When call mdtk_cnf_dispatch "bat" "pattern"
            The output should include "No cached package recommendation"
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
        It 'uses aligned recommendation labels without icons'
            export NO_COLOR=1
            _mdtk_cnf_build_index
            When call mdtk_cnf_dispatch rg
            The output should include '[SUCCESS] Found:'
            The output should include '[INFO]    Run: brew install ripgrep'
            The output should not include $'\033['
            The status should be successful
        End
        It 'recommends an exact command after earlier prefix neighbors'
            printf '%s\n' \
                'fd2c=gnu-prolog' \
                'fd2pascal=fpc' \
                'fd=fd' > "${_MDTK_CNF_TMP}/mdtk/command_index"
            When call mdtk_cnf_dispatch fd
            The output should include 'Found:'
            The output should include 'brew install fd'
            The status should be successful
        End
        It 'returns uncertain guidance without calling Homebrew on an index miss'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch bat
            The output should include "No cached package recommendation"
            The output should include "Try manually: mdtk search bat"
            The output should not include "brew-was-called"
            The status should be successful
        End
        It 'uses warning and info labels for an offline miss'
            export NO_COLOR=1
            When call mdtk_cnf_dispatch bat
            The output should include '[WARNING] No cached package recommendation'
            The output should include '[INFO]    Try manually: mdtk search bat'
            The status should be successful
        End
        It 'skips Homebrew fallback for a two-character index miss'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch ip
            The output should include 'No cached package recommendation'
            The output should include 'mdtk search ip'
            The output should not include 'brew-was-called'
            The status should be successful
        End
        It 'skips Homebrew fallback for a one-character index miss'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch x
            The output should include 'No cached package recommendation'
            The output should not include 'brew-was-called'
            The status should be successful
        End
        It 'prints a friendly not-found message when nothing matches'
            brew() { echo "brew-was-called"; }
            When call mdtk_cnf_dispatch definitely-not-real
            The output should include "No cached package recommendation"
            The output should not include "brew-was-called"
            The status should be successful
        End
    End

    Describe 'multi-backend recommendations'
        It 'prints every match and install command in fixed product order'
            _mdtk_cnf_write_backend conda 'tool=conda-tool'
            _mdtk_cnf_write_backend cargo 'tool=cargo-tool'
            _mdtk_cnf_write_backend npm 'tool=npm-tool'
            _mdtk_cnf_write_backend pip 'tool=pip-tool'
            _mdtk_cnf_write_backend homebrew 'tool=brew-tool'
            When call mdtk_cnf_dispatch tool
            The line 1 of output should include '"brew-tool" formula'
            The line 2 of output should include 'brew install brew-tool'
            The line 3 of output should include '"pip-tool" package in pip'
            The line 4 of output should include 'pip install pip-tool'
            The line 5 of output should include '"npm-tool" package in npm'
            The line 6 of output should include 'npm install --global npm-tool'
            The line 7 of output should include '"cargo-tool" package in cargo'
            The line 8 of output should include 'cargo install cargo-tool'
            The line 9 of output should include '"conda-tool" package in conda'
            The line 10 of output should include 'conda install conda-tool'
            The status should be successful
        End

        It 'prints only the subset of indexes that match'
            _mdtk_cnf_write_backend pip 'tool=pip-tool'
            _mdtk_cnf_write_backend cargo 'other=cargo-tool'
            _mdtk_cnf_write_backend conda 'tool=conda-tool'
            When call mdtk_cnf_dispatch tool
            The output should include 'package in pip'
            The output should include 'package in conda'
            The output should not include 'package in cargo'
            The status should be successful
        End

        It 'prints a scoped npm install recommendation safely'
            _mdtk_cnf_write_backend npm 'tool=@scope/tool'
            When call mdtk_cnf_dispatch tool
            The output should include 'npm install --global @scope/tool'
            The status should be successful
        End

        It 'uses the legacy Homebrew file when no isolated file exists'
            printf '%s\n' 'tool=brew-tool' > "${_MDTK_CNF_TMP}/mdtk/command_index"
            When call mdtk_cnf_dispatch tool
            The output should include 'brew install brew-tool'
            The status should be successful
        End

        It 'ignores malformed matches and continues valid indexes'
            _mdtk_cnf_write_backend pip 'tool=bad package'
            _mdtk_cnf_write_backend cargo 'tool=cargo-tool'
            When call mdtk_cnf_dispatch tool
            The output should not include 'bad package'
            The output should include 'cargo install cargo-tool'
            The status should be successful
        End

        It 'does not invoke package managers for hits'
            _mdtk_cnf_write_backend npm 'tool=npm-tool'
            When call _mdtk_cnf_dispatch_without_managers
            The output should include 'npm install --global npm-tool'
            The output should not include 'manager-was-called'
            The status should be successful
        End
    End

    Describe 'errors'
        It 'returns 1 and prints usage when no command'
            When call mdtk_cnf_dispatch ""
            The output should include "Usage:"
            The status should be failure
        End
        It 'returns guidance when brew is missing and no index'
            export PATH="/usr/bin:/bin"
            When call mdtk_cnf_dispatch rgg
            The status should be successful
            The output should include "No cached package recommendation"
        End
        It 'handles a short miss without requiring Homebrew'
            export PATH="/usr/bin:/bin"
            When call mdtk_cnf_dispatch ip
            The output should include 'No cached package recommendation'
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
