#!/usr/bin/env zsh
# ============================================================
# File:    src/logger/logger.zsh
# Purpose: Structured logging for MDTK (INFO/SUCCESS/WARNING/ERROR/DEBUG).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   The Logger module. Emits one line per message to stdout, prefixed
#   with an aligned level name: "[LEVEL] message". Honors color, no-color,
#   quiet, and debug modes. It is a leaf module: it calls no other
#   module (per .ai/ARCHITECTURE.md).
#
#   Public entry point (called by the dispatcher):
#       mdtk_logger_dispatch "$@"
#   Per-level callable functions (other modules adopt them in their
#   own issues; not wired here):
#       mdtk_logger_info / _success / _warning / _error / _debug
#
# Modes
#   - Colors:      on by default when stdout is a terminal.
#   - No-color:    off when NO_COLOR is set (any value) or --no-color.
#   - Quiet:       MDTK_LOGGER_QUIET=1 or --quiet -> emit ERROR only.
#   - Debug:       DEBUG is emitted only when MDTK_DEBUG=1 or --debug.
#
# Exit-code policy
#   - A successful emit returns 0 (including ERROR-level messages:
#     logging an error is not itself a failure).
#   - No level flag / no message on the CLI returns 1 (usage error).
#
# Parameters (mdtk_logger_dispatch)
#   $@    flags + message words. Flags: --info --success --warning
#         --error --debug --no-color --quiet --debug
#
# Return
#   0  message emitted (or correctly suppressed by mode).
#   1  usage error (no level, or no message given on the CLI).
#
# Example
#   mdtk logger --info "boot"
#   # => [INFO]    boot
#   NO_COLOR=1 mdtk logger --error "boom"
#   # => [ERROR]   boom        (no ANSI)
#   mdtk logger --quiet --info "hidden"
#   # => (no output)
#   mdtk logger --quiet --error "shown"
#   # => [ERROR]   shown
#   MDTK_DEBUG=1 mdtk logger --debug "trace"
#   # => [DEBUG]   trace
# ============================================================

# Library: utils/color owns ANSI sequences and the shared no-color policy.
source "${${(%):-%x}:A:h:h}/utils/color.zsh"

# ------------------------------------------------------------
# _mdtk_logger_color_enabled
# ------------------------------------------------------------
# Description
#   Decide whether color should be emitted. Off when the caller set
#   MDTK_LOGGER_NO_COLOR=1 (internal toggle for the --no-color flag)
#   or when the standard NO_COLOR env var is set to any value
#   (https://no-color.org/).
#
# Parameters
#   None.
#
# Return
#   0  color enabled.
#   1  color disabled.
# ------------------------------------------------------------
_mdtk_logger_color_enabled() {
    # Keep the Logger-specific toggle for its existing CLI/API contract;
    # the shared utility owns NO_COLOR and MDTK_NO_COLOR handling.
    if [[ "${MDTK_LOGGER_NO_COLOR:-0}" == "1" ]]; then
        return 1
    fi
    mdtk_utils_color_enabled
    return $?
}

# ------------------------------------------------------------
# _mdtk_logger_should_emit
# ------------------------------------------------------------
# Description
#   Decide whether a level should actually be printed, given the
#   current mode flags (quiet, debug).
#
# Parameters
#   $1    level name
#
# Return
#   0  emit this level.
#   1  suppress this level.
# ------------------------------------------------------------
_mdtk_logger_should_emit() {
    local level="$1"
    local quiet="${MDTK_LOGGER_QUIET:-0}"
    local debug_on="${MDTK_DEBUG:-0}"

    # Quiet: only ERROR survives.
    if [[ "$quiet" == "1" && "$level" != "error" ]]; then
        return 1
    fi
    # Debug level needs explicit enablement.
    if [[ "$level" == "debug" && "$debug_on" != "1" ]]; then
        return 1
    fi
    return 0
}

# ------------------------------------------------------------
# _mdtk_logger_emit
# ------------------------------------------------------------
# Description
#   Compose and print one log line: "[LEVEL] message", optionally
#   colorized. Honors color/no-color and quiet/debug suppression.
#   Writes to stdout.
#
# Parameters
#   $1    level name
#   $2    message (may be empty -> "[LEVEL] ")
#
# Return
#   0  emitted or correctly suppressed.
# ------------------------------------------------------------
_mdtk_logger_emit() {
    local level="$1"
    local message="$2"

    if ! _mdtk_logger_should_emit "$level"; then
        return 0
    fi

    if _mdtk_logger_color_enabled; then
        mdtk_utils_color_log "$level" "$message"
    else
        local MDTK_NO_COLOR=1
        mdtk_utils_color_log "$level" "$message"
    fi
    return 0
}

# ------------------------------------------------------------
# mdtk_logger_info
# ------------------------------------------------------------
# Description: emit an INFO line.
# Parameters: $1 message
# Return: 0
# Example: mdtk_logger_info "starting"
# ------------------------------------------------------------
mdtk_logger_info() {
    _mdtk_logger_emit "info" "$1"
}

# ------------------------------------------------------------
# mdtk_logger_success
# ------------------------------------------------------------
# Description: emit a SUCCESS line.
# Parameters: $1 message
# Return: 0
# Example: mdtk_logger_success "done"
# ------------------------------------------------------------
mdtk_logger_success() {
    _mdtk_logger_emit "success" "$1"
}

# ------------------------------------------------------------
# mdtk_logger_warning
# ------------------------------------------------------------
# Description: emit a WARNING line.
# Parameters: $1 message
# Return: 0
# Example: mdtk_logger_warning "slow"
# ------------------------------------------------------------
mdtk_logger_warning() {
    _mdtk_logger_emit "warning" "$1"
}

# ------------------------------------------------------------
# mdtk_logger_error
# ------------------------------------------------------------
# Description: emit an ERROR line.
# Parameters: $1 message
# Return: 0
# Example: mdtk_logger_error "failed"
# ------------------------------------------------------------
mdtk_logger_error() {
    _mdtk_logger_emit "error" "$1"
}

# ------------------------------------------------------------
# mdtk_logger_debug
# ------------------------------------------------------------
# Description: emit a DEBUG line (only when MDTK_DEBUG=1).
# Parameters: $1 message
# Return: 0
# Example: MDTK_DEBUG=1 mdtk_logger_debug "trace"
# ------------------------------------------------------------
mdtk_logger_debug() {
    _mdtk_logger_emit "debug" "$1"
}

# ------------------------------------------------------------
# _mdtk_logger_usage
# ------------------------------------------------------------
# Description: print a friendly usage message for the CLI.
# Parameters: none
# Return: 0
# ------------------------------------------------------------
_mdtk_logger_usage() {
    cat <<'EOF'
Usage: mdtk logger --<level> [options] <message>

Levels (one required):
  --info      Log at INFO.
  --success   Log at SUCCESS.
  --warning   Log at WARNING.
  --error     Log at ERROR.
  --debug     Log at DEBUG (only shown when debug mode is on).

Modes:
  --no-color  Disable color (also honors the NO_COLOR env var).
  --quiet     Show only ERROR.
  --debug     Enable debug mode (show DEBUG). Also: MDTK_DEBUG=1 env.

Example:
  mdtk logger --info "hello"
  mdtk logger --quiet --error "boom"
EOF
}

# ------------------------------------------------------------
# mdtk_logger_dispatch
# ------------------------------------------------------------
# Description
#   CLI entry point. Parses flags, picks the (last) level flag,
#   joins remaining non-flag words into a message, and emits.
#
# Parameters
#   $@    flags + message words
#
# Return
#   0  emitted (or correctly suppressed).
#   1  no level flag given, or no message provided.
#
# Example
#   mdtk_logger_dispatch --info "hello"
#   mdtk_logger_dispatch --quiet --error "boom"
# ------------------------------------------------------------
mdtk_logger_dispatch() {
    local level=""
    local msg_words=()
    local arg

    while (( $# )); do
        arg="$1"
        case "$arg" in
            --info)     level="info" ;;
            --success)  level="success" ;;
            --warning)  level="warning" ;;
            --error)    level="error" ;;
            --debug)    level="debug"; export MDTK_DEBUG=1 ;;
            --no-color) export MDTK_LOGGER_NO_COLOR=1 ;;
            --quiet)    export MDTK_LOGGER_QUIET=1 ;;
            --help|-h)
                _mdtk_logger_usage
                return 0
                ;;
            *)
                msg_words+=("$arg")
                ;;
        esac
        shift
    done

    # A level flag is required.
    if [[ -z "$level" ]]; then
        _mdtk_logger_usage
        return 1
    fi

    # Join message words with single spaces.
    local message="${msg_words[*]}"

    # Empty message is allowed for levels (prints "[LEVEL] "), but a
    # totally missing message on the CLI is a usage error.
    if (( ${#msg_words[@]} == 0 )); then
        _mdtk_logger_usage
        return 1
    fi

    _mdtk_logger_emit "$level" "$message"
    return 0
}
