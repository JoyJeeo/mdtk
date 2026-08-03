#!/usr/bin/env zsh
# ============================================================
# File:    src/utils/color.zsh
# Purpose: ANSI color helpers shared across modules.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Stateless helpers for emitting (and suppressing) ANSI color.
#   Used by the Logger module and any module that prints colored
#   output. Utils are a library, not a module (no dispatch function,
#   never call back upward).
#
# Public functions
#   mdtk_utils_color_enabled      -> 0 if color on, 1 if off
#   mdtk_utils_color_for <name>   -> ANSI sequence for a name
#   mdtk_utils_color_reset        -> the reset sequence
#   mdtk_utils_color_log <level> <message> -> aligned colored log line
#
# Convention
#   Off when NO_COLOR is set to any non-empty value (no-color.org),
#   or when MDTK_NO_COLOR=1 (internal toggle).
#
# Parameters: per function (see headers).
# Return: per function.
# Example
#   source src/utils/color.zsh
#   if mdtk_utils_color_enabled; then
#       printf '%s[INFO]%s hi\n' "$(mdtk_utils_color_for red)" "$(mdtk_utils_color_reset)"
#   fi
#   mdtk_utils_color_log "success" "Index built."
# ============================================================

typeset -r MDTK_UTILS_COLOR_ESC=$'\033'
typeset -r MDTK_UTILS_COLOR_CSI="${MDTK_UTILS_COLOR_ESC}["
typeset -r MDTK_UTILS_COLOR_RESET="${MDTK_UTILS_COLOR_CSI}0m"

# ------------------------------------------------------------
# mdtk_utils_color_enabled
# ------------------------------------------------------------
# Description: decide whether color should be emitted.
# Parameters: none.
# Return: 0 color on; 1 color off.
# ------------------------------------------------------------
mdtk_utils_color_enabled() {
    if [[ -n "${NO_COLOR:-}" ]]; then
        return 1
    fi
    if [[ "${MDTK_NO_COLOR:-0}" == "1" ]]; then
        return 1
    fi
    return 0
}

# ------------------------------------------------------------
# mdtk_utils_color_for
# ------------------------------------------------------------
# Description: return the ANSI sequence for a color name.
# Parameters: $1 name (red/green/yellow/blue/magenta/cyan/reset)
# Return: 0; prints the sequence (empty if unknown).
# ------------------------------------------------------------
mdtk_utils_color_for() {
    local name="$1"
    case "$name" in
        red)     echo "${MDTK_UTILS_COLOR_CSI}31m" ;;
        green)   echo "${MDTK_UTILS_COLOR_CSI}32m" ;;
        yellow)  echo "${MDTK_UTILS_COLOR_CSI}33m" ;;
        blue)    echo "${MDTK_UTILS_COLOR_CSI}34m" ;;
        magenta) echo "${MDTK_UTILS_COLOR_CSI}35m" ;;
        cyan)    echo "${MDTK_UTILS_COLOR_CSI}36m" ;;
        reset)   echo "$MDTK_UTILS_COLOR_RESET" ;;
        *)       echo "" ;;
    esac
}

# ------------------------------------------------------------
# mdtk_utils_color_reset
# ------------------------------------------------------------
# Description: return the ANSI reset sequence.
# Parameters: none.
# Return: 0; prints the reset sequence.
# ------------------------------------------------------------
mdtk_utils_color_reset() {
    echo "$MDTK_UTILS_COLOR_RESET"
}

# ------------------------------------------------------------
# mdtk_utils_color_log
# ------------------------------------------------------------
# Description
#   Print one log line with a fixed-width, level-colored label and plain
#   message text. The formatter owns presentation only; callers choose the
#   message and whether stdout or stderr is appropriate.
# Parameters: $1 level (info/success/warning/error/debug); $2 message.
# Return: 0 printed; 1 unknown or empty level.
# Example: mdtk_utils_color_log "warning" "Cache is stale."
# ------------------------------------------------------------
mdtk_utils_color_log() {
    local level="${1:-}"
    local message="${2:-}"
    local color_name=""

    case "$level" in
        info)    color_name="cyan" ;;
        success) color_name="green" ;;
        warning) color_name="yellow" ;;
        error)   color_name="red" ;;
        debug)   color_name="magenta" ;;
        *)       return 1 ;;
    esac

    local label="[${(U)level}]"
    if mdtk_utils_color_enabled; then
        printf '%s%-9s%s %s\n' \
            "$(mdtk_utils_color_for "$color_name")" "$label" \
            "$(mdtk_utils_color_reset)" "$message"
    else
        printf '%-9s %s\n' "$label" "$message"
    fi
    return 0
}
