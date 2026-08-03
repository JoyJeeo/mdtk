# shellcheck shell=sh
# ============================================================
# File:    tests/doctor/doctor_spec.sh
# Purpose: Behavioral coverage for MDTK Doctor diagnostics.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Exercises healthy, required-failure, warning, empty/default, malformed,
#   Unicode, whitespace, and large-index behavior without using the network.
#
# Parameters
#   None (shellspec drives the examples).
#
# Run
#   make testone FILE=tests/doctor/doctor_spec.sh
# ============================================================

MDTK_DOCTOR_BIN="${SHELLSPEC_PROJECT_ROOT}/bin/mdtk"

_mdtk_doctor_fixture() {
    export _MDTK_DOCTOR_TMP="${SHELLSPEC_TMPBASE}/doctor-${SHELLSPEC_RANDOM}"
    export HOME="${_MDTK_DOCTOR_TMP}/home"
    export XDG_CACHE_HOME="${_MDTK_DOCTOR_TMP}/cache"
    export XDG_CONFIG_HOME="${_MDTK_DOCTOR_TMP}/config"
    export PATH="${_MDTK_DOCTOR_TMP}/bin:/opt/homebrew/anaconda3/envs/mdtk/bin:/usr/bin:/bin"
    mkdir -p "$HOME" "$XDG_CACHE_HOME/mdtk" "$XDG_CONFIG_HOME/mdtk" "${_MDTK_DOCTOR_TMP}/bin"
    ln -s "$MDTK_DOCTOR_BIN" "${_MDTK_DOCTOR_TMP}/bin/mdtk"
    {
        echo '#!/bin/sh'
        echo 'if [ "$1" = "--prefix" ]; then echo /opt/homebrew; exit 0; fi'
        echo 'exit 1'
    } > "${_MDTK_DOCTOR_TMP}/bin/brew"
    chmod +x "${_MDTK_DOCTOR_TMP}/bin/brew"
    echo "source \"${SHELLSPEC_PROJECT_ROOT}/scripts/mdtk.zsh\"" > "$HOME/.zshrc"
    {
        echo 'fd=fd'
        echo 'rg=ripgrep'
    } > "$XDG_CACHE_HOME/mdtk/command_index"
    unset NO_COLOR MDTK_NO_COLOR
}

_mdtk_doctor_cleanup() {
    chmod -R u+w "${_MDTK_DOCTOR_TMP}" 2>/dev/null || true
    rm -rf "${_MDTK_DOCTOR_TMP}"
}

Describe 'mdtk doctor'
    BeforeEach '_mdtk_doctor_fixture'
    AfterEach '_mdtk_doctor_cleanup'

    It 'passes every check in a healthy environment'
        When run "$MDTK_DOCTOR_BIN" doctor
        The output should include 'macOS: available'
        The output should include 'Zsh:'
        The output should include 'Homebrew: /opt/homebrew'
        The output should include 'MDTK command:'
        The output should include 'Shell hook:'
        The output should include 'Command index: 2 entries'
        The output should include 'Doctor found no problems.'
        The status should be successful
    End

    It 'treats an unavailable Homebrew command as a required failure'
        rm -f "${_MDTK_DOCTOR_TMP}/bin/brew"
        When run "$MDTK_DOCTOR_BIN" doctor
        The output should include 'Homebrew: not found'
        The output should include 'Doctor found 1 required problem(s)'
        The status should be failure
    End

    It 'warns without failing when optional shell and index integration is absent'
        rm -f "$HOME/.zshrc" "$XDG_CACHE_HOME/mdtk/command_index"
        When run "$MDTK_DOCTOR_BIN" doctor
        The output should include 'Shell hook: not loaded'
        The output should include "Command index: missing or unreadable; run 'mdtk index build'"
        The output should include 'Doctor passed with 2 warning(s).'
        The status should be successful
    End

    It 'rejects an unknown Unicode option'
        When run "$MDTK_DOCTOR_BIN" doctor '检查'
        The error should include 'Unknown doctor option: 检查'
        The status should be failure
    End

    It 'rejects a whitespace-only option instead of treating it as empty input'
        When run "$MDTK_DOCTOR_BIN" doctor '   '
        The error should include 'Unknown doctor option:'
        The status should be failure
    End

    It 'prints help without running checks'
        When run "$MDTK_DOCTOR_BIN" doctor --help
        The output should include 'Usage: mdtk doctor [help]'
        The output should not include 'Homebrew:'
        The status should be successful
    End

    It 'rejects extra arguments'
        When run "$MDTK_DOCTOR_BIN" doctor help extra
        The error should include 'Usage: mdtk doctor [help]'
        The status should be failure
    End

    It 'validates a large sorted index'
        awk 'BEGIN { for (i = 0; i < 20000; i++) printf "cmd%05d=formula%05d\n", i, i }' > "$XDG_CACHE_HOME/mdtk/command_index"
        When run "$MDTK_DOCTOR_BIN" doctor
        The output should include 'Command index: 20000 entries'
        The output should include 'Doctor found no problems.'
        The status should be successful
    End

    It 'warns when an index is malformed'
        echo 'not-an-index-record' > "$XDG_CACHE_HOME/mdtk/command_index"
        When run "$MDTK_DOCTOR_BIN" doctor
        The output should include "Command index: invalid; run 'mdtk index build'"
        The status should be successful
    End

    It 'fails when the MDTK executable on PATH belongs to another checkout'
        rm -f "${_MDTK_DOCTOR_TMP}/bin/mdtk"
        echo '#!/bin/sh' > "${_MDTK_DOCTOR_TMP}/bin/mdtk"
        chmod +x "${_MDTK_DOCTOR_TMP}/bin/mdtk"
        When run "$MDTK_DOCTOR_BIN" doctor
        The output should include 'MDTK command: points to'
        The status should be failure
    End
End
