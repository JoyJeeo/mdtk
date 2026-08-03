#!/usr/bin/env zsh
# ============================================================
# File:    src/install/install.zsh
# Purpose: Recommend an install for a command via the Homebrew backend.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   The Install module. Given a command name, finds the Homebrew
#   formula that provides it and prints a friendly recommendation
#   (per .ai/MASTER_PROMPT.md output style: simple, no jargon, with a
#   reason and the command to run). It does NOT auto-install in v0.1.
#   Per .ai/ARCHITECTURE.md it is a module: it calls the Homebrew
#   *backend* (a leaf — allowed), does not source other modules.
#
#   Public entry point (called by the dispatcher):
#       mdtk_install_dispatch "$@"
#
# Exit-code policy
#   - 0: a recommendation was printed (formula found or a helpful
#     "not found" message).
#   - 1: usage error (no command) or brew missing.
#
# Parameters (mdtk_install_dispatch)
#   $1    command name (e.g. rg). Flags: --help.
#
# Return
#   0  recommendation printed.
#   1  no command / brew missing.
#
# Example
#   mdtk install rg
#   # => [SUCCESS] Found: the "rg" command is provided by the "ripgrep" formula.
#   # => [INFO]    Run: brew install ripgrep
# ============================================================

# Backend: homebrew (a leaf — modules may call backends).
source "${${(%):-%x}:A:h:h}/backends/homebrew.zsh"
# Shared stateless presentation utility.
source "${${(%):-%x}:A:h:h}/utils/color.zsh"

# ------------------------------------------------------------
# mdtk_install_recommend
# ------------------------------------------------------------
# Description: print a recommendation for a command (formula + run line).
# Parameters: $1 command name.
# Return: 0 if a formula was found; 1 if brew missing / no command /
#   no formula found (still prints a friendly message).
# Example: mdtk_install_recommend "rg"
# ------------------------------------------------------------
mdtk_install_recommend() {
    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        return 1
    fi
    if ! mdtk_backend_homebrew_available; then
        mdtk_utils_color_log "error" "Homebrew is not installed. mdtk install needs Homebrew." >&2
        return 1
    fi
    local formula
    formula=$(mdtk_backend_homebrew_provides "$cmd")
    if [[ -n "$formula" ]]; then
        mdtk_utils_color_log "success" "Found: the \"${cmd}\" command is provided by the \"${formula}\" formula."
        mdtk_utils_color_log "info" "Run: brew install ${formula}"
        return 0
    fi
    mdtk_utils_color_log "warning" "No Homebrew formula found that provides \"${cmd}\"."
    mdtk_utils_color_log "info" "Try: mdtk search ${cmd}"
    return 0
}

# ------------------------------------------------------------
# _mdtk_install_usage
# ------------------------------------------------------------
# Description: print a friendly usage message.
# Parameters: none. Return: 0.
# ------------------------------------------------------------
_mdtk_install_usage() {
    cat <<'EOF'
Usage: mdtk install <command>

Find the Homebrew formula that provides a command and print a
recommendation (does not install in v0.1).

Example:
  mdtk install rg
EOF
}

# ------------------------------------------------------------
# mdtk_install_dispatch
# ------------------------------------------------------------
# Description: CLI entry point. Routes to mdtk_install_recommend.
# Parameters: $1 command. Return: 0 recommendation; 1 usage/brew error.
# Example: mdtk_install_dispatch "rg"
# ------------------------------------------------------------
mdtk_install_dispatch() {
    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        _mdtk_install_usage
        return 1
    fi
    case "$cmd" in
        help|--help|-h)
            _mdtk_install_usage
            return 0
            ;;
    esac
    mdtk_install_recommend "$cmd"
    return $?
}
