# shellcheck shell=sh
# ============================================================
# File:    tests/uninstall/uninstall_spec.sh
# Purpose: Behavior tests for one-command MDTK uninstall.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   Exercises confirmation, removal, dry-run, idempotency, config
#   preservation, managed-root safety, empty input, and a large zshrc.
#   Every example uses isolated HOME/XDG/bin paths.
#
# Run
#   make testone FILE=tests/uninstall/uninstall_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/uninstall/uninstall.zsh"

_MDTK_UNINSTALL_TMP="$(mktemp -d)"

mdtk_uninstall_setup() {
    rm -rf "${_MDTK_UNINSTALL_TMP}"
    mkdir -p "${_MDTK_UNINSTALL_TMP}/home/.local/bin"
    mkdir -p "${_MDTK_UNINSTALL_TMP}/xdg-cache/mdtk"
    mkdir -p "${_MDTK_UNINSTALL_TMP}/xdg-config/mdtk"
    mkdir -p "${_MDTK_UNINSTALL_TMP}/xdg-data"
    mkdir -p "${_MDTK_UNINSTALL_TMP}/checkout/bin"
    mkdir -p "${_MDTK_UNINSTALL_TMP}/checkout/scripts"
    : > "${_MDTK_UNINSTALL_TMP}/checkout/bin/mdtk"
    : > "${_MDTK_UNINSTALL_TMP}/checkout/scripts/mdtk.zsh"
    ln -s "${_MDTK_UNINSTALL_TMP}/checkout/bin/mdtk" \
        "${_MDTK_UNINSTALL_TMP}/home/.local/bin/mdtk"
    echo "cache" > "${_MDTK_UNINSTALL_TMP}/xdg-cache/mdtk/value"
    echo "color=on" > "${_MDTK_UNINSTALL_TMP}/xdg-config/mdtk/config"
    {
        echo "export KEEP_ME=1"
        echo "# Added by mdtk installer."
        echo "source \"${_MDTK_UNINSTALL_TMP}/checkout/scripts/mdtk.zsh\""
        echo "export ALSO_KEEP=1"
    } > "${_MDTK_UNINSTALL_TMP}/home/.zshrc"

    export HOME="${_MDTK_UNINSTALL_TMP}/home"
    export XDG_CACHE_HOME="${_MDTK_UNINSTALL_TMP}/xdg-cache"
    export XDG_CONFIG_HOME="${_MDTK_UNINSTALL_TMP}/xdg-config"
    export XDG_DATA_HOME="${_MDTK_UNINSTALL_TMP}/xdg-data"
    export MDTK_UNINSTALL_ROOT="${_MDTK_UNINSTALL_TMP}/checkout"
    export MDTK_UNINSTALL_BIN_DIRS="${HOME}/.local/bin"
}

_mdtk_uninstall_verify_standard_removal() {
    [[ ! -e "${HOME}/.local/bin/mdtk" && ! -L "${HOME}/.local/bin/mdtk" ]] || return 1
    [[ ! -e "${XDG_CACHE_HOME}/mdtk" ]] || return 1
    [[ ! -e "${XDG_CONFIG_HOME}/mdtk" ]] || return 1
    grep -q "KEEP_ME" "${HOME}/.zshrc" || return 1
    grep -q "ALSO_KEEP" "${HOME}/.zshrc" || return 1
    ! grep -q "scripts/mdtk.zsh" "${HOME}/.zshrc" || return 1
    [[ -d "${MDTK_UNINSTALL_ROOT}" ]] || return 1
}

_mdtk_uninstall_run_and_verify() {
    mdtk_uninstall_dispatch --yes >/dev/null || return 1
    _mdtk_uninstall_verify_standard_removal
}

_mdtk_uninstall_dry_run_and_verify() {
    local output
    output="$(mdtk_uninstall_dispatch --dry-run)" || return 1
    echo "$output"
    [[ -L "${HOME}/.local/bin/mdtk" ]] || return 1
    [[ -d "${XDG_CACHE_HOME}/mdtk" ]] || return 1
    [[ -d "${XDG_CONFIG_HOME}/mdtk" ]] || return 1
    grep -q "scripts/mdtk.zsh" "${HOME}/.zshrc"
}

_mdtk_uninstall_eof_hook_run_and_verify() {
    mdtk_uninstall_dispatch --yes >/dev/null || return 1
    [[ ! -e "${HOME}/.local/bin/mdtk" && ! -L "${HOME}/.local/bin/mdtk" ]] || return 1
    [[ ! -e "${XDG_CACHE_HOME}/mdtk" ]] || return 1
    [[ ! -e "${XDG_CONFIG_HOME}/mdtk" ]] || return 1
    [[ ! -e "${MDTK_UNINSTALL_ROOT}" ]] || return 1
    ! grep -q "scripts/mdtk.zsh" "${HOME}/.zshrc"
}

Describe 'mdtk uninstall'
    BeforeEach 'mdtk_uninstall_setup'

    It 'removes managed links, hook, cache, and config but keeps a checkout'
        When call _mdtk_uninstall_run_and_verify
        The status should be successful
    End

    It 'cancels safely when empty input is not confirmed'
        Data 'n'
        When call mdtk_uninstall_dispatch
        The status should be successful
        The output should include 'Cancelled.'
        The path "${HOME}/.local/bin/mdtk" should be symlink
    End

    It 'shows a dry-run without changing files'
        When call _mdtk_uninstall_dry_run_and_verify
        The status should be successful
        The output should include 'Dry run: no files will be changed.'
        The output should include 'Remove command link:'
    End

    It 'removes a managed hook at zshrc EOF and continues cleanup'
        export MDTK_UNINSTALL_ROOT="${XDG_DATA_HOME}/mdtk"
        mkdir -p "${MDTK_UNINSTALL_ROOT}/bin" "${MDTK_UNINSTALL_ROOT}/scripts"
        : > "${MDTK_UNINSTALL_ROOT}/bin/mdtk"
        : > "${MDTK_UNINSTALL_ROOT}/scripts/mdtk.zsh"
        echo "$MDTK_UNINSTALL_MARKER_CONTENT" > "${MDTK_UNINSTALL_ROOT}/.mdtk-managed-install"
        rm -f "${HOME}/.local/bin/mdtk"
        ln -s "${MDTK_UNINSTALL_ROOT}/bin/mdtk" "${HOME}/.local/bin/mdtk"
        {
            echo "export KEEP_ME=1"
            echo "# Added by mdtk installer."
            echo "source \"${MDTK_UNINSTALL_ROOT}/scripts/mdtk.zsh\""
        } > "${HOME}/.zshrc"
        When call _mdtk_uninstall_eof_hook_run_and_verify
        The status should be successful
    End

    It 'keeps configuration when requested'
        mdtk_uninstall_dispatch --yes --keep-config >/dev/null
        When call test -f "${XDG_CONFIG_HOME}/mdtk/config"
        The status should be successful
    End

    It 'is idempotent'
        mdtk_uninstall_dispatch --yes >/dev/null
        When call mdtk_uninstall_dispatch --yes
        The status should be successful
        The output should include 'MDTK was uninstalled.'
    End

    It 'removes a correctly marked managed XDG install root'
        export MDTK_UNINSTALL_ROOT="${XDG_DATA_HOME}/mdtk"
        mkdir -p "${MDTK_UNINSTALL_ROOT}/bin" "${MDTK_UNINSTALL_ROOT}/scripts"
        : > "${MDTK_UNINSTALL_ROOT}/bin/mdtk"
        echo "$MDTK_UNINSTALL_MARKER_CONTENT" > "${MDTK_UNINSTALL_ROOT}/.mdtk-managed-install"
        rm -f "${HOME}/.local/bin/mdtk"
        ln -s "${MDTK_UNINSTALL_ROOT}/bin/mdtk" "${HOME}/.local/bin/mdtk"
        mdtk_uninstall_dispatch --yes >/dev/null
        When call test ! -e "${MDTK_UNINSTALL_ROOT}"
        The status should be successful
    End

    It 'refuses a marked source tree outside the XDG install path'
        echo "$MDTK_UNINSTALL_MARKER_CONTENT" > "${MDTK_UNINSTALL_ROOT}/.mdtk-managed-install"
        When call mdtk_uninstall_dispatch --yes
        The status should be failure
        The error should include 'Refusing unsafe managed install path:'
        The path "${MDTK_UNINSTALL_ROOT}" should be directory
        The path "${HOME}/.local/bin/mdtk" should be symlink
    End

    It 'rejects destructive data paths directly below HOME'
        When call _mdtk_uninstall_safe_mdtk_dir "${HOME}/mdtk"
        The status should be failure
    End

    It 'preserves a large unrelated zsh configuration'
        local i
        : > "${HOME}/.zshrc"
        for i in {1..2000}; do
            echo "export VALUE_${i}=${i}" >> "${HOME}/.zshrc"
        done
        echo "# Added by mdtk installer." >> "${HOME}/.zshrc"
        echo "source \"${MDTK_UNINSTALL_ROOT}/scripts/mdtk.zsh\"" >> "${HOME}/.zshrc"
        mdtk_uninstall_dispatch --yes >/dev/null
        When run grep -F 'export VALUE_1999=1999' "${HOME}/.zshrc"
        The status should be successful
        The output should include 'export VALUE_1999=1999'
    End

    It 'rejects an unknown option'
        When call mdtk_uninstall_dispatch --bogus
        The status should be failure
        The error should include 'Unknown uninstall option:'
        The output should include 'Usage:'
    End
End
