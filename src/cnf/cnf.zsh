#!/usr/bin/env zsh
# ============================================================
# File:    src/cnf/cnf.zsh
# Purpose: command-not-found handler module.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   The command-not-found (cnf) module. Invoked (via the dispatcher,
#   as `mdtk cnf <cmd>`) when the shell cannot find a command. It
#   looks the command up in the index (#009) first; on a miss it
#   falls back to the Homebrew backend's `provides`. Prints a
#   friendly recommendation (per .ai/MASTER_PROMPT.md output style).
#
#   Per .ai/ARCHITECTURE.md it calls the Homebrew backend and sources
#   `index.zsh` as a private component in the same module directory.
#   The component has no public dispatch entry point. Both `mdtk cnf`
#   and the public `mdtk index` alias route through this module's sole
#   `mdtk_cnf_dispatch` entry point.
#
#   Public entry point (called by the dispatcher):
#       mdtk_cnf_dispatch "$@"   (mdtk cnf <cmd>)
#
# Exit-code policy
#   - 0: a recommendation was printed, or an obvious non-command token was
#     ignored without querying Homebrew.
#   - 1: no command given, or brew missing on fallback.
#
# Parameters (mdtk_cnf_dispatch)
#   $1    the command that was not found.
#
# Return
#   0  recommendation printed.
#   1  no command / brew missing.
#
# Example
#   mdtk cnf rg
#   # => Found: the "rg" command is provided by the "ripgrep" formula.
#   # => Run: brew install ripgrep
# ============================================================

# Sibling library (same module dir): the index. Treated as a library
# here to avoid duplicating index lookup logic.
source "${${(%):-%x}:A:h}/index.zsh"
# Backend: homebrew (a leaf — modules may call backends).
source "${${(%):-%x}:A:h:h}/backends/homebrew.zsh"

# ------------------------------------------------------------
# _mdtk_cnf_command_is_searchable
# ------------------------------------------------------------
# Description
#   Accept common executable-name characters and require at least one ASCII
#   letter or underscore. This rejects pasted headings such as `4.1` before
#   they can trigger a slow Homebrew query.
# Parameters: $1 command token.
# Return: 0 if searchable; 1 if it is obvious non-command text.
# Example: _mdtk_cnf_command_is_searchable "python3.13"
# ------------------------------------------------------------
_mdtk_cnf_command_is_searchable() {
    local cmd="$1"
    [[ -n "$cmd" ]] || return 1
    case "$cmd" in
        *[!A-Za-z0-9_+@.-]*) return 1 ;;
    esac
    case "$cmd" in
        *[A-Za-z_]*) return 0 ;;
    esac
    return 1
}

# ------------------------------------------------------------
# mdtk_cnf_handle
# ------------------------------------------------------------
# Description
#   Look up a command in the index; on miss, fall back to the
#   Homebrew backend. Print a friendly recommendation.
# Parameters: $1 command.
# Return: 0 if a recommendation was printed; 1 if no command / brew
#   missing on fallback.
# Example: mdtk_cnf_handle "rg"
# ------------------------------------------------------------
mdtk_cnf_handle() {
    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        return 1
    fi
    if ! _mdtk_cnf_command_is_searchable "$cmd"; then
        return 0
    fi

    # 1. Try the command index (fast; cached on disk).
    local formula
    formula=$(mdtk_index_lookup "$cmd" 2>/dev/null)
    if [[ -n "$formula" ]]; then
        echo "Found: the \"${cmd}\" command is provided by the \"${formula}\" formula."
        echo "Run: brew install ${formula}"
        return 0
    fi

    # 2. Fall back to the Homebrew backend (slower; needs brew).
    if mdtk_backend_homebrew_available; then
        formula=$(mdtk_backend_homebrew_provides "$cmd")
        if [[ -n "$formula" ]]; then
            echo "Found: the \"${cmd}\" command is provided by the \"${formula}\" formula."
            echo "Run: brew install ${formula}"
            return 0
        fi
        echo "No Homebrew formula found that provides \"${cmd}\"."
        echo "Try: mdtk search ${cmd}"
        return 0
    fi

    echo "Command \"${cmd}\" was not found, and Homebrew is not installed."
    return 1
}

# ------------------------------------------------------------
# _mdtk_cnf_usage
# ------------------------------------------------------------
# Description: print a friendly usage message.
# Parameters: none. Return: 0.
# ------------------------------------------------------------
_mdtk_cnf_usage() {
    cat <<'EOF'
Usage: mdtk cnf <command>

Handle a command-not-found: look the command up in the MDTK index,
fall back to Homebrew, and print a recommendation.

This is normally called automatically by the shell hook in
scripts/mdtk.zsh (sourced in your .zshrc), not typed by hand.

Example:
  mdtk cnf rg
EOF
}

# ------------------------------------------------------------
# mdtk_cnf_dispatch
# ------------------------------------------------------------
# Description: CLI entry point. Routes to mdtk_cnf_handle.
# Parameters: $1 command. Return: 0 recommendation; 1 usage/brew error.
# Example: mdtk_cnf_dispatch "rg"
# ------------------------------------------------------------
mdtk_cnf_dispatch() {
    if [[ "${MDTK_CNF_ROUTE:-}" == "index" ]]; then
        _mdtk_cnf_index_dispatch "$@"
        return $?
    fi

    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        _mdtk_cnf_usage
        return 1
    fi
    case "$cmd" in
        help|--help|-h)
            _mdtk_cnf_usage
            return 0
            ;;
    esac
    mdtk_cnf_handle "$cmd"
    return $?
}
