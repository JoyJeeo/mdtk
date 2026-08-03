#!/usr/bin/env zsh
# ============================================================

# File:    src/backends/homebrew.zsh
# Purpose: Homebrew (brew) package-manager backend.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   A leaf backend that wraps the `brew` command so the search,
#   install, and cnf modules can ask Homebrew questions without each
#   re-implementing brew parsing. Per .ai/ARCHITECTURE.md it is a
#   leaf: called by modules, calls `brew` (external), never calls a
#   module or the dispatcher.
#
# Public functions
#   mdtk_backend_homebrew_available          -> 0 if brew is on PATH
#   mdtk_backend_homebrew_search <query>     -> formula names, one/line
#   mdtk_backend_homebrew_provides <command> -> formula that ships cmd
#   mdtk_backend_homebrew_install <formula>  -> run `brew install`
#
# Exit-code policy
#   - search: 0 + prints names (maybe none); 1 if brew missing.
#   - provides: 0 + prints formula (or nothing if unknown); 1 if brew
#     missing. Prints the first match only.
#   - install: forwards brew's exit code.
#
# Parameters: per function (see headers).
# Return: per function.
# Example
#   source src/backends/homebrew.zsh
#   mdtk_backend_homebrew_search "ripgrep"
#   mdtk_backend_homebrew_provides "rg"
#   mdtk_backend_homebrew_install "ripgrep"
# ============================================================

# ------------------------------------------------------------
# mdtk_backend_homebrew_available
# ------------------------------------------------------------
# Description: check whether `brew` is on PATH.
# Parameters: none.
# Return: 0 available; 1 not.
# ------------------------------------------------------------
mdtk_backend_homebrew_available() {
    # Recognize either a real `brew` command on PATH, or a `brew`
    # shell function (the latter is how tests mock brew without
    # touching the real binary).
    if (( ${+functions[brew]} )); then
        return 0
    fi
    if (( ${+commands[brew]} )); then
        return 0
    fi
    return 1
}

# ------------------------------------------------------------
# _mdtk_backend_homebrew_error
# ------------------------------------------------------------
# Description: Print a shared ERROR line, loading the color utility on demand
#   when the backend is used directly rather than through a module.
# Parameters: $1 message. Return: 0 printed.
# Example: _mdtk_backend_homebrew_error "Homebrew is not installed."
# ------------------------------------------------------------
_mdtk_backend_homebrew_error() {
    local message="$1"
    if (( ! ${+functions[mdtk_utils_color_log]} )); then
        local source_file="${functions_source[_mdtk_backend_homebrew_error]}"
        source "${source_file:A:h:h}/utils/color.zsh"
    fi
    mdtk_utils_color_log "error" "$message" >&2
}

# ------------------------------------------------------------
# _mdtk_backend_homebrew_require
# ------------------------------------------------------------
# Description: internal guard — fail fast if brew is missing.
# Parameters: none. Return: 0 ok; 1 missing (prints to stderr).
# ------------------------------------------------------------
_mdtk_backend_homebrew_require() {
    if ! mdtk_backend_homebrew_available; then
        _mdtk_backend_homebrew_error "Homebrew is not installed."
        return 1
    fi
    return 0
}

# ------------------------------------------------------------
# mdtk_backend_homebrew_search
# ------------------------------------------------------------
# Description: search formulae/casks matching a query.
# Parameters: $1 query.
# Return: 0 + prints names one per line; 1 if brew missing.
# Example: mdtk_backend_homebrew_search "ripgrep"
# ------------------------------------------------------------
mdtk_backend_homebrew_search() {
    local query="$1"
    if ! _mdtk_backend_homebrew_require; then
        return 1
    fi
    if [[ -z "$query" ]]; then
        return 0
    fi
    # `brew search` prints names one per line. Suppress stderr noise.
    brew search "$query" 2>/dev/null
    return 0
}

# ------------------------------------------------------------
# mdtk_backend_homebrew_provides
# ------------------------------------------------------------
# Description: find the formula that provides a command name.
#   Uses `brew info --json=v1` aliases + the formula name as a
#   fallback (many formulae ship a command of the same name).
# Parameters: $1 command name (e.g. rg).
# Return: 0 + prints the formula name (or nothing); 1 if brew missing.
# Example: mdtk_backend_homebrew_provides "rg"  # => ripgrep
# ------------------------------------------------------------
mdtk_backend_homebrew_provides() {
    local cmd="$1"
    if ! _mdtk_backend_homebrew_require; then
        return 1
    fi
    if [[ -z "$cmd" ]]; then
        return 0
    fi
    # First, try the formula of the same name (very common). brew
    # resolves aliases transparently, so `brew info rg` returns the
    # underlying formula (ripgrep). Use the JSON "name" field (the
    # canonical formula name), NOT the input command — that way an
    # alias like `rg` resolves to its real formula `ripgrep`.
    local same_name_json real_name
    if same_name_json=$(brew info --json=v1 "$cmd" 2>/dev/null); then
        if echo "$same_name_json" | grep -q "\"name\""; then
            real_name=$(echo "$same_name_json" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
            if [[ -n "$real_name" ]]; then
                echo "$real_name"
                return 0
            fi
            # Fallback to the input if we could not parse the name.
            echo "$cmd"
            return 0
        fi
    fi
    # Otherwise scan formulae whose `aliases` include the command.
    # Use `brew search` to limit candidates; for each, check if its
    # JSON `aliases` array contains the command as a quoted string.
    local candidate alias_json
    for candidate in $(brew search "$cmd" 2>/dev/null); do
        alias_json=$(brew info --json=v1 "$candidate" 2>/dev/null)
        # Look for "aliases" then a quoted "$cmd" within it. We avoid
        # a full JSON parser (no jq dependency); grep is enough for
        # the well-formed `brew info` output.
        if echo "$alias_json" | grep -q "\"aliases\""; then
            if echo "$alias_json" | grep -q "\"$cmd\""; then
                echo "$candidate"
                return 0
            fi
        fi
    done
    return 0
}

# ------------------------------------------------------------
# mdtk_backend_homebrew_install
# ------------------------------------------------------------
# Description: install a formula via `brew install`.
# Parameters: $1 formula.
# Return: brew's exit code; 1 if brew missing / bad args.
# Example: mdtk_backend_homebrew_install "ripgrep"
# ------------------------------------------------------------
mdtk_backend_homebrew_install() {
    local formula="$1"
    if [[ -z "$formula" ]]; then
        return 1
    fi
    if ! _mdtk_backend_homebrew_require; then
        return 1
    fi
    brew install "$formula"
    return $?
}
