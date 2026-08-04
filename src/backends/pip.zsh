#!/usr/bin/env zsh
# ============================================================
# File:    src/backends/pip.zsh
# Purpose: pip/PyPI package-manager backend.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Leaf backend for Python packages. It prefers `pip3`, falls back to `pip`,
#   queries `pip index versions`, and delegates installation to `pip install`.
#   PyPI exposes no authoritative console-command index, so `provides` is a
#   documented best-effort exact package-name query rather than an alias scan.
#
# Public functions
#   mdtk_backend_pip_available
#   mdtk_backend_pip_search <query>
#   mdtk_backend_pip_provides <command>
#   mdtk_backend_pip_install <package>
#
# Return
#   available: 0 when pip3/pip is callable; 1 otherwise.
#   search/provides: 0 + canonical package name; 1 on missing input/tool/query.
#   install: pip's exit status; 1 on missing input/tool.
#
# Example
#   mdtk_backend_pip_search "httpie"
#   mdtk_backend_pip_install "httpie"
# ============================================================

# Description: Select pip3 first, then pip, including function-based test mocks.
# Parameters: none. Return: 0 + executable name; 1 when unavailable.
# Example: tool="$(_mdtk_backend_pip_tool)"
_mdtk_backend_pip_tool() {
    if (( ${+functions[pip3]} || ${+commands[pip3]} )); then
        echo "pip3"
        return 0
    fi
    if (( ${+functions[pip]} || ${+commands[pip]} )); then
        echo "pip"
        return 0
    fi
    return 1
}

# Description: Check whether a supported pip executable is available.
# Parameters: none. Return: 0 available; 1 unavailable.
# Example: mdtk_backend_pip_available
mdtk_backend_pip_available() {
    _mdtk_backend_pip_tool >/dev/null
}

# Description: Extract the canonical package name from `pip index` output.
# Parameters: $1 complete output. Return: 0 + name; 1 malformed/empty.
# Example: _mdtk_backend_pip_parse_name "httpie (3.2.4)"
_mdtk_backend_pip_parse_name() {
    local output="${1:-}"
    local first_line="${output%%$'\n'*}"
    local name="${first_line%% *}"
    [[ -n "$name" && "$first_line" == "${name} ("* ]] || return 1
    case "$name" in
        *[!A-Za-z0-9_.-]*) return 1 ;;
    esac
    echo "$name"
}

# Description: Query PyPI for an exact package name through pip.
# Parameters: $1 query. Return: 0 + canonical name; 1 on failure/no match.
# Example: mdtk_backend_pip_search "httpie"
mdtk_backend_pip_search() {
    local query="${1:-}"
    [[ -n "$query" ]] || return 1
    local tool
    tool="$(_mdtk_backend_pip_tool)" || return 1
    local output
    output=$("$tool" index versions "$query" 2>/dev/null) || return 1
    _mdtk_backend_pip_parse_name "$output"
}

# Description: Best-effort resolve a command to an exact same-name package.
# Parameters: $1 command. Return: search status and canonical package output.
# Example: mdtk_backend_pip_provides "httpie"
mdtk_backend_pip_provides() {
    local command_name="${1:-}"
    [[ -n "$command_name" ]] || return 1
    mdtk_backend_pip_search "$command_name"
}

# Description: Delegate package installation to the selected pip executable.
# Parameters: $1 package. Return: pip status; 1 on empty input/missing pip.
# Example: mdtk_backend_pip_install "httpie"
mdtk_backend_pip_install() {
    local package="${1:-}"
    [[ -n "$package" ]] || return 1
    local tool
    tool="$(_mdtk_backend_pip_tool)" || return 1
    "$tool" install "$package"
}
