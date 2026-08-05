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
#   as a package query, then looks the command up in every local backend index.
#   It never invokes a package manager or waits for the network.
#
#   Per .ai/ARCHITECTURE.md it sources `index.zsh` as a private component in
#   the same module directory.
#   The component has no public dispatch entry point. Both `mdtk cnf`
#   and the public `mdtk index` alias route through this module's sole
#   `mdtk_cnf_dispatch` entry point.
#
#   Public entry point (called by the dispatcher):
#       mdtk_cnf_dispatch "$@"   (mdtk cnf <cmd>)
#
# Exit-code policy
#   - 0: recommendation/miss guidance printed, or non-command text ignored.
#   - 1: no command given.
#
# Parameters (mdtk_cnf_dispatch)
#   $1    the command that was not found.
#
# Return
#   0  recommendation printed.
#   1  no command.
#
# Example
#   mdtk cnf rg
#   # => [SUCCESS] Found: the "rg" command is provided by the "ripgrep" formula.
#   # => [INFO]    Run: brew install ripgrep
#   # => [SUCCESS] Found: the "rg" command matches the "ripgrep" package in cargo.
#   # => [INFO]    Run: cargo install ripgrep
# ============================================================

# Shared stateless presentation utility.
source "${${(%):-%x}:A:h:h}/utils/color.zsh"

# Sibling library (same module dir): the index. Treated as a library
# here to avoid duplicating index lookup logic.
source "${${(%):-%x}:A:h}/index.zsh"

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
# _mdtk_cnf_install_line
# ------------------------------------------------------------
# Description: print the backend-appropriate install command for one package.
# Parameters: $1 backend; $2 package. Return: 0 printed; 1 unknown backend.
# Example: _mdtk_cnf_install_line "npm" "typescript"
# ------------------------------------------------------------
_mdtk_cnf_install_line() {
    local backend="$1"
    local package="$2"
    case "$backend" in
        homebrew) printf 'brew install %s\n' "$package" ;;
        pip)      printf 'pip install %s\n' "$package" ;;
        npm)      printf 'npm install --global %s\n' "$package" ;;
        cargo)    printf 'cargo install %s\n' "$package" ;;
        conda)    printf 'conda install %s\n' "$package" ;;
        *) return 1 ;;
    esac
}

# ------------------------------------------------------------
# _mdtk_cnf_print_match
# ------------------------------------------------------------
# Description: print one validated offline match and its install command.
# Parameters: $1 command; $2 backend; $3 package. Return: 0 printed; 1 invalid.
# Example: _mdtk_cnf_print_match "rg" "cargo" "ripgrep"
# ------------------------------------------------------------
_mdtk_cnf_print_match() {
    local command="$1"
    local backend="$2"
    local package="$3"
    local install_line
    install_line=$(_mdtk_cnf_install_line "$backend" "$package") || return 1
    if [[ "$backend" == "homebrew" ]]; then
        mdtk_utils_color_log "success" \
            "Found: the \"${command}\" command is provided by the \"${package}\" formula."
    else
        mdtk_utils_color_log "success" \
            "Found: the \"${command}\" command matches the \"${package}\" package in ${backend}."
    fi
    mdtk_utils_color_log "info" "Run: ${install_line}"
    return 0
}

# ------------------------------------------------------------
# mdtk_cnf_handle
# ------------------------------------------------------------
# Description
#   Look up a command in every local index and print all matches in fixed order.
#   A miss returns immediately and is not proof a command cannot be installed.
# Parameters: $1 command; $2... original command arguments for classification.
# Return: 0 if a recommendation or miss guidance was printed; 1 if no command.
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

    local matches line backend package
    local -a hit_backends
    local matched=0
    matches=$(mdtk_index_lookup_all "$cmd" 2>/dev/null) || true
    for line in "${(@f)matches}"; do
        [[ "$line" == *'='* ]] || continue
        backend="${line%%=*}"
        package="${line#*=}"
        _mdtk_cnf_print_match "$cmd" "$backend" "$package" || continue
        hit_backends+=("$backend")
        matched=1
    done
    if (( matched )); then
        mdtk_index_stats_record "hit" "${(j:,:)hit_backends}" 2>/dev/null || true
        return 0
    fi

    mdtk_index_stats_record "miss" "-" 2>/dev/null || true
    mdtk_utils_color_log "warning" "No cached package recommendation found for \"${cmd}\"."
    mdtk_utils_color_log "info" "Try manually: mdtk search ${cmd}"
    return 0
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

Handle a command-not-found: look the command up in all MDTK offline indexes
and print every recommendation without invoking package managers or networks.

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
