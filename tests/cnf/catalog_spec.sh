# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/catalog_spec.sh
# Purpose: Tests for the popular-CLI catalog compiler (Issue #076).
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================
#
# Description
#   Covers shipped and isolated catalogs, validation, deterministic ranking,
#   deduplication, byte sorting, atomic preservation, capacity limits, Unicode,
#   empty input, large input, and the offline-only compiler boundary.
#
# Run
#   make testone FILE=tests/cnf/catalog_spec.sh
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/dispatcher.zsh"

_MDTK_CATALOG_TMP="$(mktemp -d)"
export XDG_CACHE_HOME="${_MDTK_CATALOG_TMP}/cache"
export MDTK_CATALOG_ROOT="${_MDTK_CATALOG_TMP}/catalogs"

mdtk_catalog_setup() {
    rm -rf "${_MDTK_CATALOG_TMP}/cache" "${_MDTK_CATALOG_TMP}/catalogs"
    mkdir -p "${_MDTK_CATALOG_TMP}/cache" "${_MDTK_CATALOG_TMP}/catalogs"
}

_mdtk_catalog_write() {
    local backend="$1"
    shift
    printf '%s\n' "$@" > "${MDTK_CATALOG_ROOT}/${backend}.catalog"
}

_mdtk_catalog_compile() {
    mdtk_dispatch index help >/dev/null || return 1
    mdtk_catalog_compile "$@"
}

_mdtk_catalog_compile_shipped() {
    local backend
    mdtk_dispatch index help >/dev/null || return 1
    MDTK_CATALOG_ROOT="${MDTK_ROOT}/catalogs"
    for backend in pip npm cargo conda; do
        mdtk_catalog_compile "$backend" || return 1
    done
}

_mdtk_catalog_write_large() {
    local file="${MDTK_CATALOG_ROOT}/cargo.catalog"
    local i
    : > "$file"
    for i in {1..10000}; do
        printf '%s|package%s|command%s\n' "$i" "$i" "$i" >> "$file"
    done
}

_mdtk_catalog_compile_without_managers() {
    brew() { return 99; }
    pip() { return 99; }
    pip3() { return 99; }
    npm() { return 99; }
    cargo() { return 99; }
    conda() { return 99; }
    _mdtk_catalog_compile npm
}

Describe 'popular CLI catalog compiler'
    Before 'mdtk_catalog_setup'

    Describe 'successful compilation'
        It 'compiles every catalog shipped in the repository'
            When call _mdtk_catalog_compile_shipped
            The path "${XDG_CACHE_HOME}/mdtk/index/pip.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/npm.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/cargo.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/conda.idx" should be file
            The status should be successful
        End

        It 'ships the scoped Leju Gym CLI command mapping'
            _mdtk_catalog_compile_shipped
            When call mdtk_dispatch index lookup --backend npm gym
            The output should equal '@leju-gym/gym-cli'
            The status should be successful
        End

        It 'ships the scoped Leju Gym MCP command mapping'
            _mdtk_catalog_compile_shipped
            When call mdtk_dispatch index lookup --backend npm gym-mcp
            The output should equal '@leju-gym/gym-mcp'
            The status should be successful
        End

        It 'expands command lists and removes exact duplicates'
            _mdtk_catalog_write pip \
                '10|httpie|http https http' \
                '20|httpie|http'
            _mdtk_catalog_compile pip >/dev/null
            When run cat "${XDG_CACHE_HOME}/mdtk/index/pip.idx"
            The output should equal $'http=httpie\nhttps=httpie'
            The status should be successful
        End

        It 'selects the lower numeric rank for command collisions'
            _mdtk_catalog_write cargo \
                '20|later-package|tool' \
                '10|winner-package|tool'
            _mdtk_catalog_compile cargo >/dev/null
            When call mdtk_dispatch index lookup --backend cargo tool
            The output should equal "winner-package"
            The status should be successful
        End

        It 'breaks equal-rank ties by package byte order'
            _mdtk_catalog_write conda \
                '10|zulu-package|tool' \
                '10|alpha-package|tool'
            _mdtk_catalog_compile conda >/dev/null
            When call mdtk_dispatch index lookup --backend conda tool
            The output should equal "alpha-package"
            The status should be successful
        End

        It 'writes deterministic byte-sorted output'
            _mdtk_catalog_write npm \
                '20|zulu|z-command' \
                '10|alpha|a-command'
            _mdtk_catalog_compile npm >/dev/null
            When run diff \
                "${XDG_CACHE_HOME}/mdtk/index/npm.idx" \
                =(LC_ALL=C sort -u "${XDG_CACHE_HOME}/mdtk/index/npm.idx")
            The status should be successful
        End

        It 'compiles Unicode executable names'
            _mdtk_catalog_write pip '10|unicode-tool|工具'
            _mdtk_catalog_compile pip >/dev/null
            When call mdtk_dispatch index lookup --backend pip 工具
            The output should equal "unicode-tool"
            The status should be successful
        End

        It 'supports an explicit destination'
            _mdtk_catalog_write npm '10|eslint|eslint'
            When call _mdtk_catalog_compile npm "${_MDTK_CATALOG_TMP}/custom/npm.idx"
            The path "${_MDTK_CATALOG_TMP}/custom/npm.idx" should be file
            The contents of file "${_MDTK_CATALOG_TMP}/custom/npm.idx" should equal "eslint=eslint"
            The status should be successful
        End

        It 'does not call package managers or registries'
            _mdtk_catalog_write npm '10|eslint|eslint'
            When call _mdtk_catalog_compile_without_managers
            The status should be successful
        End
    End

    Describe 'validation failures'
        It 'rejects an unsupported backend'
            When call _mdtk_catalog_compile homebrew
            The status should be failure
        End

        It 'rejects a missing catalog'
            When call _mdtk_catalog_compile pip
            The error should include "Catalog is missing"
            The status should be failure
        End

        It 'rejects an empty catalog'
            : > "${MDTK_CATALOG_ROOT}/pip.catalog"
            When call _mdtk_catalog_compile pip
            The error should include "empty"
            The status should be failure
        End

        It 'rejects a comments-only catalog'
            _mdtk_catalog_write pip '# no records'
            When call _mdtk_catalog_compile pip
            The status should be failure
        End

        It 'rejects a whitespace-only record'
            _mdtk_catalog_write pip '   '
            When call _mdtk_catalog_compile pip
            The error should include "expected three fields"
            The status should be failure
        End

        It 'rejects extra record fields'
            _mdtk_catalog_write npm '10|eslint|eslint|extra'
            When call _mdtk_catalog_compile npm
            The error should include "expected three fields"
            The status should be failure
        End

        It 'rejects a nonnumeric rank'
            _mdtk_catalog_write cargo 'high|ripgrep|rg'
            When call _mdtk_catalog_compile cargo
            The error should include "invalid rank"
            The status should be failure
        End

        It 'rejects an out-of-range rank'
            _mdtk_catalog_write cargo '0|ripgrep|rg'
            When call _mdtk_catalog_compile cargo
            The error should include "rank is out of range"
            The status should be failure
        End

        It 'parses leading-zero ranks as decimal values'
            _mdtk_catalog_write cargo \
                '000010|winner-package|tool' \
                '20|later-package|tool'
            _mdtk_catalog_compile cargo >/dev/null
            When call mdtk_dispatch index lookup --backend cargo tool
            The output should equal "winner-package"
            The status should be successful
        End

        It 'rejects ranks wider than the supported range'
            _mdtk_catalog_write cargo '0000001|ripgrep|rg'
            When call _mdtk_catalog_compile cargo
            The error should include "rank is out of range"
            The status should be failure
        End

        It 'rejects a malformed package name'
            _mdtk_catalog_write npm '10|bad package|tool'
            When call _mdtk_catalog_compile npm
            The error should include "invalid package"
            The status should be failure
        End

        It 'rejects a malformed command name'
            _mdtk_catalog_write cargo '10|ripgrep|-rg'
            When call _mdtk_catalog_compile cargo
            The error should include "invalid command"
            The status should be failure
        End

        It 'rejects oversized source catalogs before parsing'
            /bin/dd if=/dev/zero \
                of="${MDTK_CATALOG_ROOT}/cargo.catalog" \
                bs=1048576 count=13 2>/dev/null
            When call _mdtk_catalog_compile cargo
            The error should include "oversized"
            The status should be failure
        End

        It 'returns failure when the destination parent is a file'
            _mdtk_catalog_write pip '10|ruff|ruff'
            echo blocked > "${_MDTK_CATALOG_TMP}/blocked"
            When call _mdtk_catalog_compile pip "${_MDTK_CATALOG_TMP}/blocked/pip.idx"
            The error should include "File exists"
            The status should be failure
        End
    End

    Describe 'atomic and large behavior'
        It 'preserves the previous index when validation fails'
            mkdir -p "${XDG_CACHE_HOME}/mdtk/index"
            echo 'old=old-package' > "${XDG_CACHE_HOME}/mdtk/index/npm.idx"
            _mdtk_catalog_write npm 'invalid'
            _mdtk_catalog_compile npm >/dev/null 2>&1 || true
            When run cat "${XDG_CACHE_HOME}/mdtk/index/npm.idx"
            The output should equal "old=old-package"
            The status should be successful
        End

        It 'compiles and queries a 10000-record catalog'
            _mdtk_catalog_write_large
            _mdtk_catalog_compile cargo >/dev/null
            When call mdtk_dispatch index lookup --backend cargo command10000
            The output should equal "package10000"
            The status should be successful
        End
    End
End
