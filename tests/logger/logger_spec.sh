# shellcheck shell=sh
# ============================================================
# File:    tests/logger/logger_spec.sh
# Purpose: Tests for the Logger module (Issue #001).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Function-level + CLI integration tests for the Logger module.
#   Covers each level, color / no-color, quiet, debug, empty input.
#   Per .ai/TESTING.md: success, failure, edge cases, empty input.
#
# Run
#   make test
# ============================================================

# Source the module under test (function-level testing without the CLI).
MDTK_SRC="${SHELLSPEC_PROJECT_ROOT}/src/logger/logger.zsh"
# shellcheck source=/dev/null
. "$MDTK_SRC"

# CSI is the ANSI Control Sequence Introducer; used to assert color on/off.
CSI=$'\033['

Describe 'mdtk logger'
    # Reset inherited and per-example mode toggles before every example.
    # ShellSpec examples may inherit the caller's NO_COLOR, so AfterEach
    # alone cannot make the default-color contract deterministic.
    BeforeEach 'unset NO_COLOR; unset MDTK_NO_COLOR; unset MDTK_LOGGER_NO_COLOR; unset MDTK_LOGGER_QUIET; unset MDTK_DEBUG'
    AfterEach 'unset NO_COLOR; unset MDTK_NO_COLOR; unset MDTK_LOGGER_NO_COLOR; unset MDTK_LOGGER_QUIET; unset MDTK_DEBUG'

    Describe 'per-level functions'
        It 'emits an INFO line'
            When call mdtk_logger_info "boot"
            The output should include '[INFO]'
            The output should include 'boot'
            The status should be successful
        End
        It 'emits a SUCCESS line'
            When call mdtk_logger_success "done"
            The output should include '[SUCCESS]'
            The output should include 'done'
            The status should be successful
        End
        It 'emits a WARNING line'
            When call mdtk_logger_warning "careful"
            The output should include '[WARNING]'
            The output should include 'careful'
            The status should be successful
        End
        It 'emits an ERROR line'
            When call mdtk_logger_error "boom"
            The output should include '[ERROR]'
            The output should include 'boom'
            The status should be successful
        End
        It 'emits a DEBUG line when debug mode is on'
            export MDTK_DEBUG=1
            When call mdtk_logger_debug "trace"
            The output should include '[DEBUG]'
            The output should include 'trace'
            The status should be successful
        End
    End

    Describe 'color'
        It 'adds ANSI color by default'
            When call mdtk_logger_info "hi"
            The output should include "$CSI"
            The output should include '[INFO]'
            The output should include 'hi'
        End
        It 'respects the NO_COLOR env var'
            export NO_COLOR=1
            When call mdtk_logger_info "hi"
            The output should not include "$CSI"
            The output should include '[INFO] hi'
        End
        It 'respects the internal --no-color toggle'
            export MDTK_LOGGER_NO_COLOR=1
            When call mdtk_logger_info "hi"
            The output should not include "$CSI"
            The output should include '[INFO] hi'
        End
        It 'respects the shared MDTK_NO_COLOR toggle'
            export MDTK_NO_COLOR=1
            When call mdtk_logger_info "hi"
            The output should not include "$CSI"
            The output should include '[INFO] hi'
        End
    End

    Describe 'quiet mode'
        It 'suppresses INFO'
            export MDTK_LOGGER_QUIET=1
            export NO_COLOR=1
            When call mdtk_logger_info "hidden"
            The output should be blank
            The status should be successful
        End
        It 'still emits ERROR'
            export MDTK_LOGGER_QUIET=1
            export NO_COLOR=1
            When call mdtk_logger_error "shown"
            The output should include '[ERROR]'
            The output should include 'shown'
            The status should be successful
        End
    End

    Describe 'debug mode'
        It 'suppresses DEBUG when MDTK_DEBUG is unset'
            unset MDTK_DEBUG
            export NO_COLOR=1
            When call mdtk_logger_debug "x"
            The output should be blank
            The status should be successful
        End
        It 'emits DEBUG when MDTK_DEBUG=1'
            export MDTK_DEBUG=1
            export NO_COLOR=1
            When call mdtk_logger_debug "x"
            The output should include '[DEBUG]'
            The output should include 'x'
            The status should be successful
        End
    End

    Describe 'edge / empty input'
        It 'prints "[INFO] " for an empty message'
            export NO_COLOR=1
            When call mdtk_logger_info ""
            The output should equal '[INFO] '
            The status should be successful
        End
    End

    Describe 'CLI (mdtk_logger_dispatch)'
        AfterEach 'unset NO_COLOR; unset MDTK_LOGGER_NO_COLOR; unset MDTK_LOGGER_QUIET; unset MDTK_DEBUG'

        It 'emits via --info on the CLI'
            export NO_COLOR=1
            When call mdtk_logger_dispatch --info "hello"
            The output should include '[INFO]'
            The output should include 'hello'
            The status should be successful
        End
        It 'joins multiple words into one message'
            export NO_COLOR=1
            When call mdtk_logger_dispatch --info hello world
            The output should include '[INFO]'
            The output should include 'hello world'
            The status should be successful
        End
        It 'errors with usage when no level flag is given'
            export NO_COLOR=1
            When call mdtk_logger_dispatch just a message
            The status should be failure
            The output should include 'Usage:'
        End
        It 'errors with usage when a level flag is given but no message'
            export NO_COLOR=1
            When call mdtk_logger_dispatch --info
            The status should be failure
            The output should include 'Usage:'
        End
        It '--quiet suppresses INFO via the CLI'
            export NO_COLOR=1
            export MDTK_LOGGER_QUIET=1
            When call mdtk_logger_dispatch --quiet --info "hidden"
            The output should be blank
            The status should be successful
        End
    End
End
