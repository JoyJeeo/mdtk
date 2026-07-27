#!/usr/bin/env zsh
# ============================================================
# File:    src/cnf/index.zsh
# Purpose: Private command-index component of the CNF module.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Private CNF component that maps a command name to the Homebrew formula that
#   provides it. Built from `brew list --formula` + each formula's
#   aliases; persisted to a cache file under the utils cache dir as
#   `command=formula` lines. It calls the Homebrew backend and utils/path,
#   and is sourced only by `cnf.zsh` in the same module directory.
#
#   Private CLI router (called only by `mdtk_cnf_dispatch`):
#       _mdtk_cnf_index_dispatch "$@"
#   Public functions:
#       mdtk_index_build        -> rebuild the index from brew
#       mdtk_index_lookup <cmd> -> print formula or nothing
#
# Storage
#   $(mdtk_utils_path_cache_file command_index)  ; lines: command=formula
#
# Exit-code policy
#   - build: 0 on success; 1 if brew missing.
#   - lookup: 0 if found (prints formula); 1 if not found.
#   - dispatch usage error: 1.
#
# Parameters (_mdtk_cnf_index_dispatch)
#   $1    subcommand: build | lookup | path | help
#   $@..  command (for lookup)
#
# Return
#   0  success.
#   1  usage error, brew missing, or not found.
#
# Example
#   mdtk index build
#   mdtk index lookup rg
#   # => ripgrep
# ============================================================

# Library: utils/path (allowed — a library, not a module).
source "${${(%):-%x}:A:h:h}/utils/path.zsh"
# Backend: homebrew (a leaf — modules may call backends).
source "${${(%):-%x}:A:h:h}/backends/homebrew.zsh"

# ------------------------------------------------------------
# _mdtk_index_file
# ------------------------------------------------------------
# Description: resolve the index cache file path.
# Parameters: none. Return: 0; prints path.
# ------------------------------------------------------------
_mdtk_index_file() {
    mdtk_utils_path_cache_file "command_index"
}

# ------------------------------------------------------------
# mdtk_index_build
# ------------------------------------------------------------
# Description
#   Rebuild the command index from Homebrew. For each installed
#   formula, record `formula=formula` and `alias=formula` pairs.
# Parameters: none.
# Return: 0 on success; 1 if brew missing / IO failure.
# Example: mdtk_index_build
# ------------------------------------------------------------
mdtk_index_build() {
    if ! mdtk_backend_homebrew_available; then
        echo "Homebrew is not installed. mdtk index needs Homebrew." >&2
        return 1
    fi
    local file dir tmp
    file="$(_mdtk_index_file)"
    dir="${file:a:h}"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || return 1
    fi
    tmp="${file}.tmp.$$"
    : > "$tmp" 2>/dev/null || return 1
    # Collect formulae first (brew list into a variable), then process
    # in the main shell so the while-loop subshell does not isolate
    # writes to $tmp (and so locals stay scoped correctly).
    local formulae
    formulae=$(brew list --formula 2>/dev/null)
    local formula
    for formula in "${(@f)formulae}"; do
        [[ -z "$formula" ]] && continue
        echo "${formula}=${formula}" >> "$tmp"
        # Add aliases (commands the formula also ships).
        local json aliases_str alias
        json=$(brew info --json=v1 "$formula" 2>/dev/null)
        if echo "$json" | grep -q '"aliases"'; then
            # Extract the contents of the aliases array (between [ and ]).
            aliases_str=$(echo "$json" | sed -n 's/.*"aliases":\[\([^]]*\)\].*/\1/p')
            for alias in $(echo "$aliases_str" | tr ',' ' '); do
                alias="${alias//\"/}"
                alias="${alias//[[:space:]]/}"
                [[ -z "$alias" ]] && continue
                echo "${alias}=${formula}" >> "$tmp"
            done
        fi
    done
    mv -f "$tmp" "$file" || { rm -f "$tmp"; return 1; }
    return 0
}

# ------------------------------------------------------------
# mdtk_index_lookup
# ------------------------------------------------------------
# Description: print the formula for a command, or nothing if absent.
# Parameters: $1 command. Return: 0 if found; 1 if not / no command.
# Example: mdtk_index_lookup "rg"
# ------------------------------------------------------------
mdtk_index_lookup() {
    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        return 1
    fi
    local file
    file="$(_mdtk_index_file)"
    if [[ ! -r "$file" ]]; then
        return 1
    fi
    local line
    while IFS= read -r line; do
        if [[ "$line" == "${cmd}="* ]]; then
            echo "${line#*=}"
            return 0
        fi
    done < "$file"
    return 1
}

# ------------------------------------------------------------
# _mdtk_index_usage
# ------------------------------------------------------------
# Description: print a friendly usage message.
# Parameters: none. Return: 0.
# ------------------------------------------------------------
_mdtk_index_usage() {
    cat <<'EOF'
Usage: mdtk index <subcommand> [args]

Subcommands:
  build           Rebuild the command->formula index from Homebrew.
  lookup <cmd>    Print the formula that provides a command (exit 1 if absent).
  path            Print the index file path.
  help            Show this message.

Example:
  mdtk index build
  mdtk index lookup rg
EOF
}

# ------------------------------------------------------------
# _mdtk_cnf_index_dispatch
# ------------------------------------------------------------
# Description: CLI entry point. Routes build/lookup/path/help.
# Parameters: $1 subcommand, $@.. args.
# Return: 0 success; 1 usage/not-found/brew error.
# Example: _mdtk_cnf_index_dispatch lookup rg
# ------------------------------------------------------------
_mdtk_cnf_index_dispatch() {
    local sub="$1"
    shift 2>/dev/null
    case "$sub" in
        build)
            mdtk_index_build
            return $?
            ;;
        lookup)
            local cmd="$1"
            if [[ -z "$cmd" ]]; then
                _mdtk_index_usage
                return 1
            fi
            mdtk_index_lookup "$cmd"
            return $?
            ;;
        path)
            _mdtk_index_file
            return 0
            ;;
        help|--help|-h)
            _mdtk_index_usage
            return 0
            ;;
        "")
            _mdtk_index_usage
            return 1
            ;;
        *)
            echo "Unknown index subcommand: ${sub}" >&2
            _mdtk_index_usage
            return 1
            ;;
    esac
}
