# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/index_spec.sh
# Purpose: Tests for bounded command indexes (Issues #009, #033, and #075).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/cnf/index.zsh. Homebrew's complete executable metadata is
#   isolated and brew is mocked. Covers full build, lookup, malformed/missing
#   data, atomic preservation, isolated backend lookup, fixed ordering, Unicode,
#   empty, rebuild, and large input/index behavior.
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
    for i in {1..10000}; do
        echo "formula${i}(1.0):command${i} helper${i}" >> "$file"
    done
}

_mdtk_index_write_backend() {
    local backend="$1"
    shift
    local dir="${_MDTK_INDEX_TMP}/mdtk/index"
    local file="${dir}/${backend}.idx"
    mkdir -p "$dir"
    printf '%s\n' "$@" | LC_ALL=C sort -u > "$file"
}

_mdtk_index_lookup_large_command() {
    local command="${(l:10000::x:)}"
    mdtk_dispatch index lookup --all "$command"
}

_mdtk_index_limits_are_bounded() {
    local backend maximum
    local total=0
    mdtk_dispatch index help >/dev/null || return 1
    for backend in "${MDTK_INDEX_BACKENDS[@]}"; do
        maximum=$(_mdtk_index_backend_max_bytes "$backend") || return 1
        (( total += maximum ))
    done
    (( total == 83886080 ))
}

_mdtk_index_lookup_timed() {
    local command="$1"
    local start elapsed
    zmodload zsh/datetime
    start="$EPOCHREALTIME"
    mdtk_dispatch index lookup "$command" >/dev/null 2>&1 || true
    elapsed=$(( EPOCHREALTIME - start ))
    (( elapsed < 2.0 ))
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
        It 'writes the index in deterministic byte order'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_metadata \
                'zulu(1.0):z-command' \
                'alpha(1.0):a-command'
            mdtk_dispatch index build >/dev/null
            When run diff \
                "${_MDTK_INDEX_TMP}/mdtk/command_index" \
                =(LC_ALL=C sort -u "${_MDTK_INDEX_TMP}/mdtk/command_index")
            The status should be successful
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
        It 'finds an exact command after lexically earlier prefix neighbors'
            printf '%s\n' \
                'fd2c=gnu-prolog' \
                'fd2pascal=fpc' \
                'fd=fd' \
                'fdblock=execline' > "${_MDTK_INDEX_TMP}/mdtk/command_index"
            When call mdtk_dispatch index lookup fd
            The output should equal "fd"
            The status should be successful
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
            export NO_COLOR=1
            When call mdtk_dispatch index build
            The status should be failure
            The error should include "[ERROR]   Homebrew is not installed"
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
            When call mdtk_dispatch index lookup helper10000
            The output should equal "formula10000"
            The status should be successful
        End
        It 'looks up hits within two seconds across at least 20000 records'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_large_metadata
            mdtk_dispatch index build >/dev/null
            When call _mdtk_index_lookup_timed helper10000
            The status should be successful
        End
        It 'looks up misses within two seconds across at least 20000 records'
            brew() { _mdtk_index_mock_brew "$@"; }
            _mdtk_index_write_large_metadata
            mdtk_dispatch index build >/dev/null
            When call _mdtk_index_lookup_timed definitely-not-present
            The status should be successful
        End
        It 'rejects a malformed matching record'
            echo 'rg=not valid formula' > "${_MDTK_INDEX_TMP}/mdtk/command_index"
            When call mdtk_dispatch index lookup rg
            The output should be blank
            The status should be failure
        End
        It 'rejects an oversized index before lookup'
            local file="${_MDTK_INDEX_TMP}/mdtk/command_index"
            /bin/dd if=/dev/zero of="$file" bs=1048576 count=9 2>/dev/null
            When call mdtk_dispatch index lookup rg
            The output should be blank
            The status should be failure
        End
    End

    Describe 'isolated backend lookup'
        It 'bounds the five backend files to 80 MiB total'
            When call _mdtk_index_limits_are_bounded
            The status should be successful
        End
        It 'queries one selected backend without changing legacy output'
            echo 'rg=legacy-ripgrep' > "${_MDTK_INDEX_TMP}/mdtk/command_index"
            _mdtk_index_write_backend homebrew 'rg=new-ripgrep'
            _mdtk_index_write_backend pip 'rg=ripgrep-py'
            When call mdtk_dispatch index lookup --backend pip rg
            The output should equal "ripgrep-py"
            The status should be successful
        End
        It 'keeps the default lookup on the legacy Homebrew index'
            echo 'rg=ripgrep' > "${_MDTK_INDEX_TMP}/mdtk/command_index"
            _mdtk_index_write_backend homebrew 'rg=different-formula'
            When call mdtk_dispatch index lookup rg
            The output should equal "ripgrep"
            The status should be successful
        End
        It 'uses the legacy Homebrew index as selected-backend fallback'
            echo 'rg=ripgrep' > "${_MDTK_INDEX_TMP}/mdtk/command_index"
            When call mdtk_dispatch index lookup --backend homebrew rg
            The output should equal "ripgrep"
            The status should be successful
        End
        It 'accepts a scoped npm package name'
            _mdtk_index_write_backend npm 'serve=@scope/serve'
            When call mdtk_dispatch index lookup --backend npm serve
            The output should equal "@scope/serve"
            The status should be successful
        End
        It 'uses exact matching around lexical prefix neighbors'
            _mdtk_index_write_backend cargo \
                'fd2c=neighbor-one' \
                'fd2pascal=neighbor-two' \
                'fd=fd-find' \
                'fdblock=neighbor-three'
            When call mdtk_dispatch index lookup --backend cargo fd
            The output should equal "fd-find"
            The status should be successful
        End
        It 'supports Unicode command keys'
            _mdtk_index_write_backend conda '工具=unicode-tool'
            When call mdtk_dispatch index lookup --backend conda 工具
            The output should equal "unicode-tool"
            The status should be successful
        End
        It 'returns every match in fixed product order'
            _mdtk_index_write_backend conda 'serve=conda-serve'
            _mdtk_index_write_backend cargo 'serve=cargo-serve'
            _mdtk_index_write_backend npm 'serve=serve'
            _mdtk_index_write_backend pip 'serve=serve-cli'
            _mdtk_index_write_backend homebrew 'serve=serve'
            When call mdtk_dispatch index lookup --all serve
            The line 1 of output should equal "homebrew=serve"
            The line 2 of output should equal "pip=serve-cli"
            The line 3 of output should equal "npm=serve"
            The line 4 of output should equal "cargo=cargo-serve"
            The line 5 of output should equal "conda=conda-serve"
            The status should be successful
        End
        It 'continues across missing backend index files'
            _mdtk_index_write_backend npm 'eslint=eslint'
            When call mdtk_dispatch index lookup --all eslint
            The output should equal "npm=eslint"
            The status should be successful
        End
        It 'returns 1 when no backend matches'
            _mdtk_index_write_backend npm 'eslint=eslint'
            When call mdtk_dispatch index lookup --all absent
            The output should be blank
            The status should be failure
        End
        It 'rejects malformed cached package names'
            _mdtk_index_write_backend npm 'serve=not a package'
            When call mdtk_dispatch index lookup --backend npm serve
            The output should be blank
            The status should be failure
        End
        It 'rejects an oversized isolated backend index'
            mkdir -p "${_MDTK_INDEX_TMP}/mdtk/index"
            /bin/dd if=/dev/zero \
                of="${_MDTK_INDEX_TMP}/mdtk/index/homebrew.idx" \
                bs=1048576 count=9 2>/dev/null
            When call mdtk_dispatch index lookup --backend homebrew rg
            The output should be blank
            The status should be failure
        End
        It 'rejects unknown backends without evaluating input'
            When call mdtk_dispatch index lookup --backend '$(echo unsafe)' rg
            The output should be blank
            The error should include "Unknown index backend"
            The status should be failure
        End
        It 'rejects empty selected-backend commands with usage'
            When call mdtk_dispatch index lookup --backend npm ""
            The output should include "Usage:"
            The status should be failure
        End
        It 'handles a large command key without invoking a backend'
            _mdtk_index_write_backend npm 'eslint=eslint'
            When call _mdtk_index_lookup_large_command
            The output should be blank
            The status should be failure
        End
    End

    Describe 'path'
        It 'prints the index file path'
            When call mdtk_dispatch index path
            The output should include "command_index"
            The status should be successful
        End
        It 'prints a validated isolated backend path'
            When call mdtk_dispatch index path --backend npm
            The output should end with "/mdtk/index/npm.idx"
            The status should be successful
        End
        It 'prints the manifest contract path'
            When call mdtk_dispatch index path --manifest
            The output should end with "/mdtk/index/manifest"
            The status should be successful
        End
        It 'rejects an unknown backend path'
            When call mdtk_dispatch index path --backend unknown
            The output should include "Usage:"
            The status should be failure
        End
    End
End
