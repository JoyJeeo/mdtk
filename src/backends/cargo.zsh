#!/usr/bin/env zsh
# ============================================================
# File:    src/backends/cargo.zsh
# Purpose: Cargo/crates.io package-manager backend.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Leaf backend that wraps `cargo search` and `cargo install`. Crates.io does
#   not expose a complete binary-to-crate index through Cargo, so `provides`
#   accepts only an exact same-name crate from search results.
#
# Public functions
#   mdtk_backend_cargo_available
#   mdtk_backend_cargo_search <query>
#   mdtk_backend_cargo_provides <command>
#   mdtk_backend_cargo_install <crate>
#
# Return
#   available: 0 when Cargo is callable; 1 otherwise.
#   search: 0 + crate names; 1 on invalid input/tool/search failure.
#   provides: 0 + exact crate; 1 when absent or unavailable.
#   install: Cargo status; 1 on invalid input/tool.
#
# Example
#   mdtk_backend_cargo_search "ripgrep"
#   mdtk_backend_cargo_install "ripgrep"
# ============================================================

# Description: Check for a Cargo command or function-based test mock.
# Parameters: none. Return: 0 available; 1 unavailable.
# Example: mdtk_backend_cargo_available
mdtk_backend_cargo_available() {
    (( ${+functions[cargo]} || ${+commands[cargo]} ))
}

# Description: Parse `cargo search` output into validated crate names.
# Parameters: $1 output. Return: 0 with zero or more names.
# Example: _mdtk_backend_cargo_parse_search 'ripgrep = "14.1.0" # text'
_mdtk_backend_cargo_parse_search() {
    local output="${1:-}"
    local line name
    for line in "${(@f)output}"; do
        [[ "$line" == *' = "'* ]] || continue
        name="${line%% = \"*}"
        [[ -n "$name" ]] || continue
        case "$name" in
            *[!A-Za-z0-9_-]*) continue ;;
        esac
        echo "$name"
    done
    return 0
}

# Description: Search crates.io and print crate names one per line.
# Parameters: $1 query. Return: 0 search completed; 1 failure.
# Example: mdtk_backend_cargo_search "ripgrep"
mdtk_backend_cargo_search() {
    local query="${1:-}"
    [[ -n "$query" ]] || return 1
    mdtk_backend_cargo_available || return 1
    local output
    output=$(cargo search --limit 10 --color never "$query" 2>/dev/null) || return 1
    _mdtk_backend_cargo_parse_search "$output"
}

# Description: Resolve an exact same-name crate as a best-effort binary owner.
# Parameters: $1 command. Return: 0 + crate; 1 when no exact result.
# Example: mdtk_backend_cargo_provides "ripgrep"
mdtk_backend_cargo_provides() {
    local command_name="${1:-}"
    [[ -n "$command_name" ]] || return 1
    local crate
    for crate in "${(@f)$(mdtk_backend_cargo_search "$command_name")}"; do
        if [[ "$crate" == "$command_name" ]]; then
            echo "$crate"
            return 0
        fi
    done
    return 1
}

# Description: Delegate crate installation to Cargo.
# Parameters: $1 crate. Return: Cargo status; 1 empty input/missing Cargo.
# Example: mdtk_backend_cargo_install "ripgrep"
mdtk_backend_cargo_install() {
    local crate="${1:-}"
    [[ -n "$crate" ]] || return 1
    mdtk_backend_cargo_available || return 1
    cargo install "$crate"
}
