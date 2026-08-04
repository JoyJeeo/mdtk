#!/usr/bin/env zsh
# ============================================================
# File:    src/backends/conda.zsh
# Purpose: conda package-manager backend.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Leaf backend for configured conda channels. It parses the stable tabular
#   `conda search` output into unique package names and delegates installation.
#   Conda exposes no portable command-to-package index, so `provides` accepts
#   only an exact same-name package from search results.
#
# Public functions
#   mdtk_backend_conda_available
#   mdtk_backend_conda_search <query>
#   mdtk_backend_conda_provides <command>
#   mdtk_backend_conda_install <package>
#
# Return
#   available: 0 when conda is callable; 1 otherwise.
#   search: 0 + package names; 1 on invalid input/tool/search failure.
#   provides: 0 + exact package; 1 when absent/unavailable.
#   install: conda status; 1 on invalid input/tool.
#
# Example
#   mdtk_backend_conda_search "httpie"
#   mdtk_backend_conda_install "httpie"
# ============================================================

# Description: Check for a conda command or function-based test mock.
# Parameters: none. Return: 0 available; 1 unavailable.
# Example: mdtk_backend_conda_available
mdtk_backend_conda_available() {
    (( ${+functions[conda]} || ${+commands[conda]} ))
}

# Description: Parse tabular conda-search output into unique package names.
# Parameters: $1 output. Return: 0 with zero or more names.
# Example: _mdtk_backend_conda_parse_search "$output"
_mdtk_backend_conda_parse_search() {
    local output="${1:-}"
    local line name
    local -A seen=()
    for line in "${(@f)output}"; do
        [[ -n "$line" ]] || continue
        case "$line" in
            \#*|'Loading channels:'*|'Channels:'*|'No match found'*) continue ;;
        esac
        name="${line%%[[:space:]]*}"
        [[ -n "$name" ]] || continue
        case "$name" in
            *[!A-Za-z0-9_.-]*) continue ;;
        esac
        [[ -n "${seen[$name]:-}" ]] && continue
        seen[$name]=1
        echo "$name"
    done
    return 0
}

# Description: Search configured conda channels and print unique package names.
# Parameters: $1 query. Return: 0 completed; 1 invalid/tool/search failure.
# Example: mdtk_backend_conda_search "httpie"
mdtk_backend_conda_search() {
    local query="${1:-}"
    [[ -n "$query" ]] || return 1
    mdtk_backend_conda_available || return 1
    local output
    output=$(conda search "$query" 2>/dev/null) || return 1
    _mdtk_backend_conda_parse_search "$output"
}

# Description: Resolve an exact same-name package as a best-effort command owner.
# Parameters: $1 command. Return: 0 + package; 1 no exact result.
# Example: mdtk_backend_conda_provides "httpie"
mdtk_backend_conda_provides() {
    local command_name="${1:-}"
    [[ -n "$command_name" ]] || return 1
    local package
    for package in "${(@f)$(mdtk_backend_conda_search "$command_name")}"; do
        if [[ "$package" == "$command_name" ]]; then
            echo "$package"
            return 0
        fi
    done
    return 1
}

# Description: Delegate package installation to conda.
# Parameters: $1 package. Return: conda status; 1 invalid/missing tool.
# Example: mdtk_backend_conda_install "httpie"
mdtk_backend_conda_install() {
    local package="${1:-}"
    [[ -n "$package" ]] || return 1
    mdtk_backend_conda_available || return 1
    conda install "$package"
}
