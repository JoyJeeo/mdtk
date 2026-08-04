#!/usr/bin/env zsh
# ============================================================
# File:    src/backends/npm.zsh
# Purpose: npm registry package-manager backend.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Leaf backend that parses `npm search --parseable`, checks exact same-name
#   package `bin.<command>` metadata, and delegates global CLI installation.
#   Command mapping is intentionally exact and best-effort; npm has no complete
#   registry-wide binary index.
#
# Public functions
#   mdtk_backend_npm_available
#   mdtk_backend_npm_search <query>
#   mdtk_backend_npm_provides <command>
#   mdtk_backend_npm_install <package>
#
# Return
#   available: 0 when npm is callable; 1 otherwise.
#   search: 0 + package names; 1 invalid/tool/search failure.
#   provides: 0 + exact package; 1 absent/unavailable.
#   install: npm status; 1 invalid/tool.
#
# Example
#   mdtk_backend_npm_search "typescript"
#   mdtk_backend_npm_install "typescript"
# ============================================================

# Description: Check for an npm command or function-based test mock.
# Parameters: none. Return: 0 available; 1 unavailable.
# Example: mdtk_backend_npm_available
mdtk_backend_npm_available() {
    (( ${+functions[npm]} || ${+commands[npm]} ))
}

# Description: Parse tab-separated npm search output into unique package names.
# Parameters: $1 output. Return: 0 with zero or more names.
# Example: _mdtk_backend_npm_parse_search "$output"
_mdtk_backend_npm_parse_search() {
    local output="${1:-}"
    local line name
    local -A seen=()
    for line in "${(@f)output}"; do
        name="${line%%$'\t'*}"
        [[ -n "$name" ]] || continue
        case "$name" in
            *[!A-Za-z0-9@/_.-]*) continue ;;
        esac
        [[ -n "${seen[$name]:-}" ]] && continue
        seen[$name]=1
        echo "$name"
    done
    return 0
}

# Description: Search the npm registry and print package names one per line.
# Parameters: $1 query. Return: 0 completed; 1 invalid/tool/search failure.
# Example: mdtk_backend_npm_search "typescript"
mdtk_backend_npm_search() {
    local query="${1:-}"
    [[ -n "$query" ]] || return 1
    mdtk_backend_npm_available || return 1
    local output
    output=$(npm search "$query" --parseable --searchlimit=10 2>/dev/null) || return 1
    _mdtk_backend_npm_parse_search "$output"
}

# Description: Resolve a same-name package whose bin metadata owns the command.
# Parameters: $1 command. Return: 0 + package; 1 absent/invalid/tool failure.
# Example: mdtk_backend_npm_provides "typescript"
mdtk_backend_npm_provides() {
    local command_name="${1:-}"
    [[ -n "$command_name" ]] || return 1
    case "$command_name" in
        *[!A-Za-z0-9_.-]*) return 1 ;;
    esac
    mdtk_backend_npm_available || return 1
    local bin_path
    bin_path=$(npm view "$command_name" "bin.${command_name}" --json 2>/dev/null) || return 1
    [[ -n "$bin_path" && "$bin_path" != "null" ]] || return 1
    echo "$command_name"
}

# Description: Delegate global CLI installation to npm.
# Parameters: $1 package. Return: npm status; 1 invalid/missing tool.
# Example: mdtk_backend_npm_install "typescript"
mdtk_backend_npm_install() {
    local package="${1:-}"
    [[ -n "$package" ]] || return 1
    mdtk_backend_npm_available || return 1
    npm install --global "$package"
}
