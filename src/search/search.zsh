#!/usr/bin/env zsh
# ============================================================
# File:    src/search/search.zsh
# Purpose: Search packages through a selected package-manager backend.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Search defaults to Homebrew for compatibility and supports explicit pip,
#   cargo, conda, and npm selection. The module routes through fixed cases to
#   leaf backends; it never constructs or evaluates function names.
#
# Parameters (mdtk_search_dispatch)
#   --backend <name>  homebrew (default), pip, cargo, conda, or npm.
#   <query>           one required package query token.
#
# Return
#   0 search completed, including an empty result; 1 usage/tool/search failure.
#
# Example
#   mdtk search ripgrep
#   mdtk search --backend pip httpie
# ============================================================

local _mdtk_search_src_root="${${(%):-%x}:A:h:h}"
source "${_mdtk_search_src_root}/backends/homebrew.zsh"
source "${_mdtk_search_src_root}/backends/pip.zsh"
source "${_mdtk_search_src_root}/backends/cargo.zsh"
source "${_mdtk_search_src_root}/backends/conda.zsh"
source "${_mdtk_search_src_root}/backends/npm.zsh"
source "${_mdtk_search_src_root}/utils/color.zsh"
unset _mdtk_search_src_root

# Description: Check availability for one validated backend name.
# Parameters: $1 backend. Return: backend availability status; 1 unknown.
# Example: _mdtk_search_backend_available "pip"
_mdtk_search_backend_available() {
    local backend="$1"
    case "$backend" in
        homebrew) mdtk_backend_homebrew_available ;;
        pip)      mdtk_backend_pip_available ;;
        cargo)    mdtk_backend_cargo_available ;;
        conda)    mdtk_backend_conda_available ;;
        npm)      mdtk_backend_npm_available ;;
        *)        return 1 ;;
    esac
}

# Description: Dispatch one query through a validated available backend.
# Parameters: $1 backend; $2 query. Return: backend search status.
# Example: _mdtk_search_backend_query "npm" "typescript"
_mdtk_search_backend_query() {
    local backend="$1"
    local query="$2"
    case "$backend" in
        homebrew) mdtk_backend_homebrew_search "$query" ;;
        pip)      mdtk_backend_pip_search "$query" ;;
        cargo)    mdtk_backend_cargo_search "$query" ;;
        conda)    mdtk_backend_conda_search "$query" ;;
        npm)      mdtk_backend_npm_search "$query" ;;
        *)        return 1 ;;
    esac
}

# Description: Search one backend after validating query and availability.
# Parameters: $1 query; $2 optional backend (default homebrew).
# Return: 0 completed; 1 invalid/unavailable/backend failure.
# Example: mdtk_search_query "httpie" "pip"
mdtk_search_query() {
    local query="${1:-}"
    local backend="${2:-homebrew}"
    [[ -n "$query" ]] || return 1
    case "$backend" in
        homebrew|pip|cargo|conda|npm) ;;
        *)
            mdtk_utils_color_log "error" "Unknown package backend: ${backend}" >&2
            return 1
            ;;
    esac
    if ! _mdtk_search_backend_available "$backend"; then
        if [[ "$backend" == "homebrew" ]]; then
            mdtk_utils_color_log "error" "Homebrew is not installed. mdtk search needs Homebrew." >&2
        else
            mdtk_utils_color_log "error" "Package backend is not available: ${backend}" >&2
        fi
        return 1
    fi
    _mdtk_search_backend_query "$backend" "$query"
}

# Description: Print Search CLI usage.
# Parameters: none. Return: 0.
# Example: _mdtk_search_usage
_mdtk_search_usage() {
    cat <<'EOF'
Usage: mdtk search [--backend <name>] <query>

Backends:
  homebrew  Homebrew formulae/casks (default)
  pip       Python packages on PyPI
  cargo     Rust crates on crates.io
  conda     Packages in configured conda channels
  npm       Packages in the npm registry

Examples:
  mdtk search ripgrep
  mdtk search --backend npm typescript
EOF
}

# Description: Parse Search CLI options and execute one backend query.
# Parameters: documented in file header. Return: 0 success/help; 1 error.
# Example: mdtk_search_dispatch --backend cargo ripgrep
mdtk_search_dispatch() {
    local backend="homebrew"
    local query=""
    while (( $# )); do
        case "$1" in
            --backend)
                shift
                if [[ -z "${1:-}" ]]; then
                    mdtk_utils_color_log "error" "Option --backend requires a name." >&2
                    return 1
                fi
                backend="$1"
                ;;
            help|--help|-h)
                _mdtk_search_usage
                return 0
                ;;
            -*)
                mdtk_utils_color_log "error" "Unknown search option: $1" >&2
                return 1
                ;;
            *)
                if [[ -n "$query" ]]; then
                    mdtk_utils_color_log "error" "Search accepts one query." >&2
                    return 1
                fi
                query="$1"
                ;;
        esac
        shift
    done
    if [[ -z "$query" ]]; then
        _mdtk_search_usage
        return 1
    fi
    mdtk_search_query "$query" "$backend"
}
