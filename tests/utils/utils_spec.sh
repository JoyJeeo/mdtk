# shellcheck shell=sh
# ============================================================
# File:    tests/utils/utils_spec.sh
# Purpose: Tests for the Utils library (Issue #003).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/utils/{path,color,shell}.zsh. Each example runs
#   against isolated XDG / HOME so it never touches the developer's
#   real paths. Covers success, failure, edge, empty (.ai/TESTING.md).
#
# Run
#   make test
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/utils/path.zsh"
. "${MDTK_ROOT}/src/utils/color.zsh"
. "${MDTK_ROOT}/src/utils/shell.zsh"

CSI=$'\033['

Describe 'mdtk utils'
    Describe 'path'
        It 'resolves the project root'
            When call mdtk_utils_path_root
            The output should include "mdtk"
            The status should be successful
        End
        It 'resolves the config file path under XDG_CONFIG_HOME'
            export XDG_CONFIG_HOME="/tmp/xdg-$$"
            When call mdtk_utils_path_config
            The output should include "/mdtk/config"
            The status should be successful
        End
        It 'falls back to $HOME/.config when XDG is empty'
            unset XDG_CONFIG_HOME
            export HOME="/tmp/home-$$"
            When call mdtk_utils_path_config
            The output should include ".config/mdtk/config"
            The status should be successful
        End
        It 'resolves a named cache file under the cache dir'
            export XDG_CACHE_HOME="/tmp/xdg-cache-$$"
            When call mdtk_utils_path_cache_file "command_index"
            The output should include "/mdtk/command_index"
            The status should be successful
        End
        It 'handles an empty cache-file name'
            export XDG_CACHE_HOME="/tmp/xdg-cache-$$"
            When call mdtk_utils_path_cache_file ""
            The output should include "/mdtk/"
            The status should be successful
        End
    End

    Describe 'color'
        AfterEach 'unset NO_COLOR; unset MDTK_NO_COLOR'
        It 'is enabled by default'
            unset NO_COLOR
            unset MDTK_NO_COLOR
            When call mdtk_utils_color_enabled
            The status should be successful
        End
        It 'is disabled when NO_COLOR is set'
            export NO_COLOR=1
            When call mdtk_utils_color_enabled
            The status should be failure
        End
        It 'is disabled when MDTK_NO_COLOR=1'
            unset NO_COLOR
            export MDTK_NO_COLOR=1
            When call mdtk_utils_color_enabled
            The status should be failure
        End
        It 'returns an ANSI sequence for a known name'
            When call mdtk_utils_color_for "red"
            The output should include "$CSI"
            The status should be successful
        End
        It 'returns empty for an unknown name'
            When call mdtk_utils_color_for "nopesauce"
            The output should be blank
            The status should be successful
        End
        It 'returns a reset sequence'
            When call mdtk_utils_color_reset
            The output should include "$CSI"
            The status should be successful
        End
    End

    Describe 'shell'
        It 'prints the zsh version'
            When call mdtk_utils_shell_zsh_version
            The output should not be blank
            The status should be successful
        End
        It 'reads an env var with a default when unset'
            unset MDTK_SOME_MISSING_VAR
            When call mdtk_utils_shell_env_get "MDTK_SOME_MISSING_VAR" "0"
            The output should equal "0"
            The status should be successful
        End
        It 'reads an env var that is set'
            export MDTK_TEST_PRESENT=yes
            When call mdtk_utils_shell_env_get "MDTK_TEST_PRESENT" "0"
            The output should equal "yes"
            The status should be successful
        End
    End
End
