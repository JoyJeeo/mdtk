#!/usr/bin/env zsh
# ============================================================
# File:    src/cache/cache.zsh
# Purpose: Store and retrieve cached results for MDTK.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   The Cache module. Stores named blobs (e.g. brew search snapshots,
#   command index) under an XDG-aware cache dir. Sources utils/path
#   (a library, not a module — allowed by .ai/ARCHITECTURE.md rule 4).
#   Does NOT call any other module.
#
#   Public entry point (called by the dispatcher):
#       mdtk_cache_dispatch "$@"
#   Public functions (other modules call via the dispatcher, or via
#   the cache module's own API when sourced as a library by the cnf
#   module's siblings — see .ai/ARCHITECTURE.md):
#       mdtk_cache_get <name>
#       mdtk_cache_set <name> <value>
#       mdtk_cache_clean [name]
#
# Storage format
#   One file per cache name under the cache dir. The value is the file
#   body (multi-line allowed). Names are restricted to [a-z0-9_]+.
#
# Location
#   $(mdtk_utils_path_cache_dir)/<name>   (XDG-aware, see utils/path)
#
# Exit-code policy
#   - get of a missing cache: prints nothing, returns 1.
#   - get of a present cache: prints contents, returns 0.
#   - set: returns 0 on success, 1 on bad name / IO failure.
#   - clean: returns 0.
#   - dispatch usage error: returns 1.
#
# Parameters (mdtk_cache_dispatch)
#   $1    subcommand: get | set | clean | path | list | help
#   $@..  name [/ value]
#
# Return
#   0  success.
#   1  usage error, missing entry, or IO failure.
#
# Example
#   mdtk cache set snapshot "line1\nline2"
#   mdtk cache get snapshot
#   mdtk cache clean
# ============================================================

# Library: utils/path (allowed — a library, not a module).
source "${${(%):-%x}:A:h:h}/utils/path.zsh"

# ------------------------------------------------------------
# _mdtk_cache_validate_name
# ------------------------------------------------------------
# Description: ensure a cache name matches [a-z0-9_]+.
# Parameters: $1 name. Return: 0 valid; 1 invalid/empty.
# ------------------------------------------------------------
_mdtk_cache_validate_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        return 1
    fi
    if [[ "$name" =~ ^[a-z0-9_]+$ ]]; then
        return 0
    fi
    return 1
}

# ------------------------------------------------------------
# mdtk_cache_get
# ------------------------------------------------------------
# Description: print the contents of a named cache entry.
# Parameters: $1 name. Return: 0 present; 1 absent/invalid.
# Example: mdtk_cache_get "command_index"
# ------------------------------------------------------------
mdtk_cache_get() {
    local name="$1"
    if ! _mdtk_cache_validate_name "$name"; then
        return 1
    fi
    local file
    file="$(mdtk_utils_path_cache_file "$name")"
    if [[ ! -r "$file" ]]; then
        return 1
    fi
    cat "$file"
    return 0
}

# ------------------------------------------------------------
# mdtk_cache_set
# ------------------------------------------------------------
# Description: write a value to a named cache entry (multi-line ok).
# Parameters: $1 name, $2 value.
# Return: 0 stored; 1 invalid name / IO failure.
# Example: mdtk_cache_set "snapshot" "data"
# ------------------------------------------------------------
mdtk_cache_set() {
    local name="$1"
    local value="$2"
    if ! _mdtk_cache_validate_name "$name"; then
        return 1
    fi
    local dir file
    dir="$(mdtk_utils_path_cache_dir)"
    file="$(mdtk_utils_path_cache_file "$name")"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || return 1
    fi
    printf '%s' "$value" > "$file" 2>/dev/null || return 1
    return 0
}

# ------------------------------------------------------------
# mdtk_cache_clean
# ------------------------------------------------------------
# Description: remove one cache entry (if a name is given) or the
# whole cache dir's contents (if no name).
# Parameters: $1 name (optional).
# Return: 0 always.
# Example: mdtk_cache_clean; mdtk_cache_clean "snapshot"
# ------------------------------------------------------------
mdtk_cache_clean() {
    local name="$1"
    local dir
    dir="$(mdtk_utils_path_cache_dir)"
    if [[ -n "$name" ]]; then
        if _mdtk_cache_validate_name "$name"; then
            local file
            file="$(mdtk_utils_path_cache_file "$name")"
            rm -f "$file" 2>/dev/null
        fi
        return 0
    fi
    if [[ -d "$dir" ]]; then
        # (N) = NULL_GLOB locally on this expansion, so empty dir does
        # not error on `*`. rm -f ignores missing operands anyway.
        rm -f "${dir}"/*(N) 2>/dev/null
    fi
    return 0
}

# ------------------------------------------------------------
# _mdtk_cache_list
# ------------------------------------------------------------
# Description: list cache entry names (one per line).
# Parameters: none. Return: 0.
# ------------------------------------------------------------
_mdtk_cache_list() {
    local dir
    dir="$(mdtk_utils_path_cache_dir)"
    if [[ -d "$dir" ]]; then
        # setopt NULL_GLOB would let `*` expand to nothing when empty;
        # but we avoid touching global options in a library. Use a
        # safe loop that does not fail on no matches.
        local f
        for f in "$dir"/*(N); do
            if [[ -f "$f" ]]; then
                echo "${f:t}"
            fi
        done
    fi
    return 0
}

# ------------------------------------------------------------
# _mdtk_cache_usage
# ------------------------------------------------------------
# Description: print a friendly usage message.
# Parameters: none. Return: 0.
# ------------------------------------------------------------
_mdtk_cache_usage() {
    cat <<'EOF'
Usage: mdtk cache <subcommand> [args]

Subcommands:
  get <name>           Print the contents of a cache entry (exit 1 if absent).
  set <name> <value>   Store a value in a cache entry.
  clean [name]         Remove one entry, or all entries if no name.
  list                 List cache entry names.
  path                 Print the cache directory path.
  help                 Show this message.

Example:
  mdtk cache set snapshot "data"
  mdtk cache get snapshot
EOF
}

# ------------------------------------------------------------
# mdtk_cache_dispatch
# ------------------------------------------------------------
# Description: CLI entry point. Routes get/set/clean/list/path/help.
# Parameters: $1 subcommand, $@.. args.
# Return: 0 success; 1 usage/missing/IO error.
# Example: mdtk_cache_dispatch set snapshot "data"
# ------------------------------------------------------------
mdtk_cache_dispatch() {
    local sub="$1"
    shift 2>/dev/null

    case "$sub" in
        get)
            local name="$1"
            if [[ -z "$name" ]]; then
                _mdtk_cache_usage
                return 1
            fi
            mdtk_cache_get "$name"
            return $?
            ;;
        set)
            local name="$1"
            local value="$2"
            if [[ -z "$name" ]]; then
                _mdtk_cache_usage
                return 1
            fi
            mdtk_cache_set "$name" "$value"
            return $?
            ;;
        clean)
            mdtk_cache_clean "$1"
            return 0
            ;;
        list)
            _mdtk_cache_list
            return 0
            ;;
        path)
            mdtk_utils_path_cache_dir
            return 0
            ;;
        help|--help|-h)
            _mdtk_cache_usage
            return 0
            ;;
        "")
            _mdtk_cache_usage
            return 1
            ;;
        *)
            echo "Unknown cache subcommand: ${sub}" >&2
            _mdtk_cache_usage
            return 1
            ;;
    esac
}
