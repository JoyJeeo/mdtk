# shellcheck shell=sh
# ============================================================
# File:    tests/scripts/catalog_check_spec.sh
# Purpose: Tests for offline catalog validation tooling (Issue #083).
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================
#
# Description
#   Covers shipped-catalog success, invalid/empty/large catalogs, unsupported
#   arguments, temporary cleanup, and the package-manager/network boundary.
#
# Run
#   make testone FILE=tests/scripts/catalog_check_spec.sh
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
MDTK_CATALOG_CHECK="${MDTK_ROOT}/scripts/catalog-check.zsh"
_MDTK_CATALOG_CHECK_TMP="$(mktemp -d)"

mdtk_catalog_check_setup() {
    rm -rf "${_MDTK_CATALOG_CHECK_TMP}/catalogs" \
        "${_MDTK_CATALOG_CHECK_TMP}/bin" \
        "${_MDTK_CATALOG_CHECK_TMP}/user-cache"
    rm -f "${_MDTK_CATALOG_CHECK_TMP}/manager-called"
    mkdir -p "${_MDTK_CATALOG_CHECK_TMP}/catalogs"
}

_mdtk_catalog_check_copy_shipped() {
    cp "${MDTK_ROOT}"/catalogs/*.catalog \
        "${_MDTK_CATALOG_CHECK_TMP}/catalogs/"
}

_mdtk_catalog_check_run() {
    MDTK_CATALOG_ROOT="${1:-${MDTK_ROOT}/catalogs}" \
        TMPDIR="${_MDTK_CATALOG_CHECK_TMP}" \
        XDG_CACHE_HOME="${_MDTK_CATALOG_CHECK_TMP}/user-cache" \
        "${MDTK_CATALOG_CHECK}"
}

_mdtk_catalog_check_large() {
    _mdtk_catalog_check_copy_shipped
    local i
    : > "${_MDTK_CATALOG_CHECK_TMP}/catalogs/cargo.catalog"
    for i in {1..10000}; do
        printf '%s|package%s|command%s\n' "$i" "$i" "$i" \
            >> "${_MDTK_CATALOG_CHECK_TMP}/catalogs/cargo.catalog"
    done
    _mdtk_catalog_check_run "${_MDTK_CATALOG_CHECK_TMP}/catalogs"
}

_mdtk_catalog_check_without_managers() {
    local fake_bin="${_MDTK_CATALOG_CHECK_TMP}/bin"
    local manager
    mkdir -p "$fake_bin"
    for manager in brew pip pip3 npm cargo conda curl git; do
        {
            echo '#!/bin/sh'
            echo 'echo called >> "${MDTK_MANAGER_MARKER}"'
            echo 'exit 99'
        } > "${fake_bin}/${manager}"
        chmod +x "${fake_bin}/${manager}"
    done
    MDTK_MANAGER_MARKER="${_MDTK_CATALOG_CHECK_TMP}/manager-called" \
        PATH="${fake_bin}:${PATH}" \
        _mdtk_catalog_check_run "${MDTK_ROOT}/catalogs"
}

Describe 'offline catalog validation tool'
    Before 'mdtk_catalog_check_setup'

    It 'validates every shipped catalog and reports capacity evidence'
        When call _mdtk_catalog_check_run "${MDTK_ROOT}/catalogs"
        The output should include 'pip catalog:'
        The output should include 'npm catalog:'
        The output should include 'cargo catalog:'
        The output should include 'conda catalog:'
        The output should include 'All catalogs valid:'
        The output should include 'bytes compiled offline.'
        The status should be successful
    End

    It 'does not invoke package managers, registries, Git, or curl'
        When call _mdtk_catalog_check_without_managers
        The output should include 'All catalogs valid:'
        The path "${_MDTK_CATALOG_CHECK_TMP}/manager-called" should not be exist
        The status should be successful
    End

    It 'returns failure for an invalid catalog while checking later backends'
        _mdtk_catalog_check_copy_shipped
        echo 'invalid' > "${_MDTK_CATALOG_CHECK_TMP}/catalogs/npm.catalog"
        When call _mdtk_catalog_check_run "${_MDTK_CATALOG_CHECK_TMP}/catalogs"
        The output should include 'cargo catalog:'
        The error should include 'npm catalog: failed'
        The status should be failure
    End

    It 'returns failure for an empty catalog'
        _mdtk_catalog_check_copy_shipped
        : > "${_MDTK_CATALOG_CHECK_TMP}/catalogs/pip.catalog"
        When call _mdtk_catalog_check_run "${_MDTK_CATALOG_CHECK_TMP}/catalogs"
        The output should include 'conda catalog:'
        The error should include 'Catalog is missing, empty, unreadable, or oversized'
        The status should be failure
    End

    It 'validates a large catalog without writing user indexes'
        When call _mdtk_catalog_check_large
        The output should include 'cargo catalog: 10000 commands'
        The path "${_MDTK_CATALOG_CHECK_TMP}/user-cache/mdtk/index/cargo.idx" should not be exist
        The status should be successful
    End

    It 'cleans temporary compilation directories after validation'
        _mdtk_catalog_check_run "${MDTK_ROOT}/catalogs" >/dev/null
        count="$(find "${_MDTK_CATALOG_CHECK_TMP}" -maxdepth 1 \
            -type d -name 'mdtk-catalog-check.*' | wc -l | tr -d ' ')"
        When call echo "$count"
        The output should equal '0'
        The status should be successful
    End

    It 'prints help without validating catalogs'
        When run "${MDTK_CATALOG_CHECK}" --help
        The output should include 'Usage: ./scripts/catalog-check.zsh'
        The output should not include 'catalog: '
        The status should be successful
    End

    It 'rejects unexpected, whitespace, and Unicode arguments'
        When run "${MDTK_CATALOG_CHECK}" ' 工具 '
        The error should include 'Usage: ./scripts/catalog-check.zsh'
        The status should be failure
    End
End
