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
#   as `mdtk cnf <cmd> [args...]`) when the shell cannot find a command. It
#   first classifies the complete shell field to avoid treating pasted prose
#   as a package query, then
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
        -*) return 1 ;;
        *[!A-Za-z0-9_+@.-]*) return 1 ;;
    esac
    case "$cmd" in
        *[A-Za-z_]*) return 0 ;;
    esac
    return 1
}

# ------------------------------------------------------------
# _mdtk_cnf_input_is_searchable
# ------------------------------------------------------------
# Description
#   Classify a complete command-not-found field without disk or external I/O.
#   Command-shaped fields (single tokens, options, paths, or assignments) are
#   searchable. Obvious headings, prose, sentence punctuation, and oversized
#   pasted fields are ignored.
# Parameters: $1 command token; $2... original command arguments.
# Return: 0 if CNF should search; 1 if the field looks like pasted text.
# Example: _mdtk_cnf_input_is_searchable "rg" "--hidden" "中文.txt"
# ------------------------------------------------------------
_mdtk_cnf_input_is_searchable() {
    local cmd="$1"
    shift 2>/dev/null
    _mdtk_cnf_command_is_searchable "$cmd" || return 1
    (( ${#cmd} <= 255 )) || return 1
    (( $# )) || return 0

    local total_length="${#cmd}"
    local arg command_signal=0 text_signal=0
    for arg in "$@"; do
        (( total_length += ${#arg} + 1 ))
        (( total_length <= 512 )) || return 1
        case "$arg" in
            *$'\n'*|*$'\r'*) return 1 ;;
            -*|*/*|*=*) command_signal=1 ;;
        esac
        case "$arg" in
            *。*|*，*|*；*|*：*|*！*|*？*|*、*|*'.'|*','|*':'|*';'|*'?'|*'!')
                text_signal=1
                ;;
        esac
    done

    (( command_signal )) && return 0
    (( text_signal )) && return 1
    case "$cmd" in
        [A-Z]*) return 1 ;;
    esac
    # Two or more plain arguments are syntactically indistinguishable from a
    # short prose phrase. Require an option/path/assignment signal above;
    # retain a single plain argument for common `tool pattern` invocations.
    (( $# < 2 )) || return 1
    (( total_length <= 120 )) || return 1
    return 0
}

# ------------------------------------------------------------
# mdtk_cnf_handle
# ------------------------------------------------------------
# Description
#   Look up a command in the index; on miss, fall back to the
#   Homebrew backend for command names of at least three characters. Short
#   index misses return immediately because broad package searches for highly
#   ambiguous one- and two-character names can block the interactive shell.
# Parameters: $1 command; $2... original command arguments for classification.
# Return: 0 if a recommendation was printed; 1 if no command / brew
#   missing on fallback.
# Example: mdtk_cnf_handle "rg"
# ------------------------------------------------------------
mdtk_cnf_handle() {
    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        return 1
    fi
    if ! _mdtk_cnf_input_is_searchable "$@"; then
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

    # Short names are highly ambiguous in Homebrew and can turn an interactive
    # command-not-found lookup into a minutes-long search. Index hits above are
    # still recommended; only the broad fallback is skipped.
    if (( ${#cmd} < 3 )); then
        echo "Skipped automatic Homebrew search for short command \"${cmd}\"."
        echo "Run manually: mdtk search ${cmd}"
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
Usage: mdtk cnf <command> [arguments...]

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
# Parameters: $1 command; $2... original arguments for input classification.
# Return: 0 recommendation/ignored text; 1 usage/brew error.
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
    mdtk_cnf_handle "$@"
    return $?
}
