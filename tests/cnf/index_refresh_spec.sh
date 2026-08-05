# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/index_refresh_spec.sh
# Purpose: Tests for multi-backend index build and refresh (Issue #077).
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================
#
# Description
#   Uses isolated Homebrew metadata and repository-catalog fixtures to cover
#   all/single refresh, fixed backend order, manifests, partial failure,
#   old-index preservation, legacy compatibility, invalid CLI input, and the
#   explicit offline catalog boundary.
#
# Run
#   make testone FILE=tests/cnf/index_refresh_spec.sh
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/dispatcher.zsh"

_MDTK_REFRESH_TMP="$(mktemp -d)"
export XDG_CACHE_HOME="${_MDTK_REFRESH_TMP}/cache"
export MDTK_CATALOG_ROOT="${_MDTK_REFRESH_TMP}/catalogs"

mdtk_refresh_setup() {
    rm -rf "${_MDTK_REFRESH_TMP}/cache" \
        "${_MDTK_REFRESH_TMP}/catalogs" \
        "${_MDTK_REFRESH_TMP}/brew-cache" \
        "${_MDTK_REFRESH_TMP}/brew-called"
    mkdir -p "${_MDTK_REFRESH_TMP}/cache" \
        "${_MDTK_REFRESH_TMP}/catalogs" \
        "${_MDTK_REFRESH_TMP}/brew-cache/api/internal"
    printf '%s\n' '10|pip-package|tool' > "${MDTK_CATALOG_ROOT}/pip.catalog"
    printf '%s\n' '10|npm-package|tool' > "${MDTK_CATALOG_ROOT}/npm.catalog"
    printf '%s\n' '10|cargo-package|tool' > "${MDTK_CATALOG_ROOT}/cargo.catalog"
    printf '%s\n' '10|conda-package|tool' > "${MDTK_CATALOG_ROOT}/conda.catalog"
    printf '%s\n' 'brew-package(1.0):tool brew-tool' \
        > "${_MDTK_REFRESH_TMP}/brew-cache/api/internal/executables.txt"
}

_mdtk_refresh_mock_brew() {
    if [[ "$1" == "--cache" ]]; then
        printf '%s\n' "${_MDTK_REFRESH_TMP}/brew-cache"
    elif [[ "$1" == "which-formula" ]]; then
        return 1
    fi
}

_mdtk_refresh_recording_brew() {
    printf '%s\n' "$*" >> "${_MDTK_REFRESH_TMP}/brew-called"
    _mdtk_refresh_mock_brew "$@"
}

Describe 'multi-backend index refresh'
    Before 'mdtk_refresh_setup'
    BeforeEach 'unfunction brew 2>/dev/null || true'

    Describe 'all backends'
        It 'builds all five indexes, the legacy file, and a manifest'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            When call mdtk_dispatch index build
            The path "${XDG_CACHE_HOME}/mdtk/index/homebrew.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/pip.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/npm.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/cargo.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/conda.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/command_index" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/manifest" should be file
            The output should be blank
            The status should be successful
        End

        It 'records every successful backend in fixed manifest order'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            mdtk_dispatch index build >/dev/null
            When run sed -n '4,8p' "${XDG_CACHE_HOME}/mdtk/index/manifest"
            The output should equal $'homebrew=rebuilt\npip=rebuilt\nnpm=rebuilt\ncargo=rebuilt\nconda=rebuilt'
            The status should be successful
        End

        It 'makes every built match available in fixed query order'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            mdtk_dispatch index refresh >/dev/null
            When call mdtk_dispatch index lookup --all tool
            The output should equal $'homebrew=brew-package\npip=pip-package\nnpm=npm-package\ncargo=cargo-package\nconda=conda-package'
            The status should be successful
        End

        It 'keeps the legacy Homebrew lookup contract after all-backend build'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            mdtk_dispatch index build >/dev/null
            When call mdtk_dispatch index lookup brew-tool
            The output should equal "brew-package"
            The status should be successful
        End
    End

    Describe 'selected backend'
        It 'builds only a selected catalog backend without invoking brew'
            brew() { _mdtk_refresh_recording_brew "$@"; }
            When call mdtk_dispatch index build --backend npm
            The path "${XDG_CACHE_HOME}/mdtk/index/npm.idx" should be file
            The path "${XDG_CACHE_HOME}/mdtk/index/homebrew.idx" should not be exist
            The path "${_MDTK_REFRESH_TMP}/brew-called" should not be exist
            The status should be successful
        End

        It 'records nonselected backends explicitly in the manifest'
            brew() { _mdtk_refresh_recording_brew "$@"; }
            mdtk_dispatch index refresh --backend cargo >/dev/null
            When run cat "${XDG_CACHE_HOME}/mdtk/index/manifest"
            The output should include "selection=cargo"
            The output should include "homebrew=not-selected"
            The output should include "cargo=rebuilt"
            The output should include "conda=not-selected"
            The status should be successful
        End

        It 'refreshes the selected backend through the explicit alias'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            mdtk_dispatch index refresh --backend pip >/dev/null
            printf '%s\n' '10|new-package|new-tool' > "${MDTK_CATALOG_ROOT}/pip.catalog"
            mdtk_dispatch index refresh --backend pip >/dev/null
            When call mdtk_dispatch index lookup --backend pip new-tool
            The output should equal "new-package"
            The status should be successful
        End

        It 'builds selected Homebrew metadata into isolated and legacy files'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            When call mdtk_dispatch index build --backend homebrew
            The contents of file "${XDG_CACHE_HOME}/mdtk/index/homebrew.idx" should include "tool=brew-package"
            The contents of file "${XDG_CACHE_HOME}/mdtk/command_index" should include "tool=brew-package"
            The status should be successful
        End
    End

    Describe 'failure isolation'
        It 'preserves a failed catalog backend and continues the others'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            mkdir -p "${XDG_CACHE_HOME}/mdtk/index"
            printf '%s\n' 'old=old-npm' > "${XDG_CACHE_HOME}/mdtk/index/npm.idx"
            printf '%s\n' 'invalid record' > "${MDTK_CATALOG_ROOT}/npm.catalog"
            When call mdtk_dispatch index refresh
            The contents of file "${XDG_CACHE_HOME}/mdtk/index/npm.idx" should equal "old=old-npm"
            The path "${XDG_CACHE_HOME}/mdtk/index/conda.idx" should be file
            The error should include "Could not rebuild npm"
            The status should be failure
        End

        It 'records partial failures after continuing the build'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            printf '%s\n' 'invalid record' > "${MDTK_CATALOG_ROOT}/npm.catalog"
            mdtk_dispatch index build >/dev/null 2>&1 || true
            When run cat "${XDG_CACHE_HOME}/mdtk/index/manifest"
            The output should include "homebrew=rebuilt"
            The output should include "npm=failed"
            The output should include "conda=rebuilt"
            The status should be successful
        End

        It 'preserves Homebrew indexes and still compiles catalogs when brew is missing'
            mkdir -p "${XDG_CACHE_HOME}/mdtk/index"
            printf '%s\n' 'old=old-brew' > "${XDG_CACHE_HOME}/mdtk/index/homebrew.idx"
            printf '%s\n' 'old=old-brew' > "${XDG_CACHE_HOME}/mdtk/command_index"
            export PATH="/usr/bin:/bin"
            export NO_COLOR=1
            When call mdtk_dispatch index refresh
            The contents of file "${XDG_CACHE_HOME}/mdtk/index/homebrew.idx" should equal "old=old-brew"
            The contents of file "${XDG_CACHE_HOME}/mdtk/command_index" should equal "old=old-brew"
            The path "${XDG_CACHE_HOME}/mdtk/index/pip.idx" should be file
            The error should include "Homebrew is not installed"
            The status should be failure
        End

        It 'preserves Homebrew indexes when refreshed metadata is invalid'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            mkdir -p "${XDG_CACHE_HOME}/mdtk/index"
            printf '%s\n' 'old=old-brew' > "${XDG_CACHE_HOME}/mdtk/index/homebrew.idx"
            printf '%s\n' 'old=old-brew' > "${XDG_CACHE_HOME}/mdtk/command_index"
            printf '%s\n' 'invalid metadata' \
                > "${_MDTK_REFRESH_TMP}/brew-cache/api/internal/executables.txt"
            When call mdtk_dispatch index refresh --backend homebrew
            The contents of file "${XDG_CACHE_HOME}/mdtk/index/homebrew.idx" should equal "old=old-brew"
            The contents of file "${XDG_CACHE_HOME}/mdtk/command_index" should equal "old=old-brew"
            The error should include "metadata is invalid"
            The status should be failure
        End

        It 'returns failure when the manifest target is invalid after building indexes'
            brew() { _mdtk_refresh_mock_brew "$@"; }
            mkdir -p "${XDG_CACHE_HOME}/mdtk/index/manifest"
            When call mdtk_dispatch index refresh --backend npm
            The path "${XDG_CACHE_HOME}/mdtk/index/npm.idx" should be file
            The error should include "Could not update the MDTK index manifest"
            The status should be failure
        End
    End

    Describe 'CLI validation'
        It 'rejects a missing selected backend'
            When call mdtk_dispatch index refresh --backend
            The output should include "Usage:"
            The status should be failure
        End

        It 'rejects an unknown selected backend'
            When call mdtk_dispatch index build --backend unknown
            The output should include "Usage:"
            The status should be failure
        End

        It 'rejects extra refresh arguments'
            When call mdtk_dispatch index refresh --backend npm extra
            The output should include "Usage:"
            The status should be failure
        End

        It 'rejects positional backend arguments'
            When call mdtk_dispatch index build npm
            The output should include "Usage:"
            The status should be failure
        End
    End
End
