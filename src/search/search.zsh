#!/usr/bin/env zsh
# ============================================================
# File:    src/search/search.zsh
# Purpose: Search packages via the Homebrew backend.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   The Search module. Queries the Homebrew backend for packages
#   matching a query, prints results one per line. Per
#   .ai/ARCHITECTURE.md it is a module: it does NOT source other
#   modules (no sourcing cache/config); it calls the Homebrew
#   *backend* (a leaf — allowed: modules call backends).
#
#   Public entry point (called by the dispatcher):
#       mdtk_search_dispatch "$@"
#
# Exit-code policy
#   - search: 0 + prints names (maybe none); 1 on usage error or
#     brew missing (error message to stderr).
#
# Parameters (mdtk_search_dispatch)
#   $1    query (required).
#   $@..  (single query token in v0.1)
#
# Return
#   0  results printed (or none found).
#   1  no query / brew missing.
#
# Example
#   mdtk search ripgrep
#   # => ripgrep
#   # => ripgrep-all
# ============================================================

# Backend: homebrew (a leaf backend — modules may call backends).
source "${${(%):-%x}:A:h:h}/backends/homebrew.zsh"
# Shared stateless presentation utility.
source "${${(%):-%x}:A:h:h}/utils/color.zsh"

# ------------------------------------------------------------
# mdtk_search_query
# ------------------------------------------------------------
# Description: run a search via the Homebrew backend and print names.
# Parameters: $1 query. Return: 0; 1 if brew missing / empty query.
# Example: mdtk_search_query "ripgrep"
# ------------------------------------------------------------
mdtk_search_query() {
    local query="$1"
    if [[ -z "$query" ]]; then
        return 1
    fi
    if ! mdtk_backend_homebrew_available; then
        mdtk_utils_color_log "error" "Homebrew is not installed. mdtk search needs Homebrew." >&2
        return 1
    fi
    mdtk_backend_homebrew_search "$query"
    return 0
}

# ------------------------------------------------------------
# _mdtk_search_usage
# ------------------------------------------------------------
# Description: print a friendly usage message.
# Parameters: none. Return: 0.
# ------------------------------------------------------------
_mdtk_search_usage() {
    cat <<'EOF'
Usage: mdtk search <query>

Search Homebrew formulae for a query and print matches, one per line.

Example:
  mdtk search ripgrep
EOF
}

# ------------------------------------------------------------
# mdtk_search_dispatch
# ------------------------------------------------------------
# Description: CLI entry point. Routes a query to mdtk_search_query.
# Parameters: $1 query. Return: 0 results; 1 usage/brew error.
# Example: mdtk_search_dispatch "ripgrep"
# ------------------------------------------------------------
mdtk_search_dispatch() {
    local query="$1"
    if [[ -z "$query" ]]; then
        _mdtk_search_usage
        return 1
    fi
    case "$query" in
        help|--help|-h)
            _mdtk_search_usage
            return 0
            ;;
    esac
    mdtk_search_query "$query"
    return $?
}
