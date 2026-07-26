# shellcheck shell=sh
# ============================================================
# File:    tests/config/config_spec.sh
# Purpose: Tests for the Config module (Issue #002).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Function-level + CLI tests for the Config module. Each example
#   runs against an isolated XDG_CONFIG_HOME so it never touches the
#   developer's real config. Covers get/set round-trip, missing key,
#   overwrite, empty value, and large input (.ai/TESTING.md).
#
# Run
#   make test
# ============================================================

MDTK_SRC="${SHELLSPEC_PROJECT_ROOT}/src/config/config.zsh"
# shellcheck source=/dev/null
. "$MDTK_SRC"

# Isolated config dir per spec run.
_MDTK_CONFIG_TMP="$(mktemp -d)"
export XDG_CONFIG_HOME="${_MDTK_CONFIG_TMP}"
unset HOME 2>/dev/null || true

mdtk_config_setup() {
    rm -rf "${_MDTK_CONFIG_TMP}"
    mkdir -p "${_MDTK_CONFIG_TMP}"
}

Describe 'mdtk config'
    Before 'mdtk_config_setup'

    Describe 'get / set round-trip'
        It 'returns 1 and prints nothing for a missing key'
            When call mdtk_config_get "nope"
            The output should be blank
            The status should be failure
        End
        It 'stores and returns a value'
            mdtk_config_set "color" "on" >/dev/null
            When call mdtk_config_get "color"
            The output should equal "on"
            The status should be successful
        End
    End

    Describe 'overwrite'
        It 'replaces an existing value'
            mdtk_config_set "k" "v1" >/dev/null
            mdtk_config_set "k" "v2" >/dev/null
            When call mdtk_config_get "k"
            The output should equal "v2"
            The status should be successful
        End
    End

    Describe 'edge / empty input'
        It 'accepts an empty value'
            mdtk_config_set "k" "" >/dev/null
            When call mdtk_config_get "k"
            The output should be blank
            The status should be successful
        End
        It 'returns 1 when get is given no key'
            When call mdtk_config_get ""
            The status should be failure
        End
    End

    Describe 'large input'
        It 'stores a value with many keys and reads them back'
            _many() {
                local i
                for i in {1..200}; do
                    mdtk_config_set "k${i}" "v${i}" >/dev/null
                done
            }
            _many
            When call mdtk_config_get "k199"
            The output should equal "v199"
            The status should be successful
        End
    End

    Describe 'CLI (mdtk_config_dispatch)'
        It 'sets and gets via the CLI'
            mdtk_config_dispatch set color on >/dev/null
            When call mdtk_config_dispatch get color
            The output should equal "on"
            The status should be successful
        End
        It 'list prints all pairs'
            mdtk_config_dispatch set a 1 >/dev/null
            mdtk_config_dispatch set b 2 >/dev/null
            When call mdtk_config_dispatch list
            The output should include "a=1"
            The output should include "b=2"
            The status should be successful
        End
        It 'path prints the config file path'
            When call mdtk_config_dispatch path
            The output should include "mdtk/config"
            The status should be successful
        End
        It 'usage error when get has no key'
            When call mdtk_config_dispatch get
            The status should be failure
            The output should include "Usage:"
        End
        It 'usage error on unknown subcommand'
            When call mdtk_config_dispatch bogus
            The status should be failure
            The error should include "Unknown config subcommand"
            The output should include "Usage:"
        End
    End
End
