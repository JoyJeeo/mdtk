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
#   provides it. Built from Homebrew's complete executable metadata so formulae
#   do not need to be installed first; persisted to a cache file under the
#   utils cache dir as `command=formula` lines. It calls the Homebrew backend
#   and utils/path, and is sourced only by `cnf.zsh` in the same module.
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

typeset -r MDTK_INDEX_MAX_BYTES=8388608

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
# _mdtk_index_homebrew_executables_file
# ------------------------------------------------------------
# Description: resolve Homebrew's cached complete executable metadata file.
# Parameters: none. Return: 0 and prints path; 1 if unresolved.
# Example: _mdtk_index_homebrew_executables_file
# ------------------------------------------------------------
_mdtk_index_homebrew_executables_file() {
    local cache_dir
    cache_dir=$(brew --cache 2>/dev/null) || return 1
    [[ -n "$cache_dir" ]] || return 1
    printf '%s\n' "${cache_dir}/api/internal/executables.txt"
}

# ------------------------------------------------------------
# _mdtk_index_write_full
# ------------------------------------------------------------
# Description: parse Homebrew executable metadata into command=formula lines.
# Parameters: $1 source metadata file; $2 destination file.
# Return: 0 if at least one valid entry was written; 1 otherwise.
# Example: _mdtk_index_write_full "$source_file" "$tmp_file"
# ------------------------------------------------------------
_mdtk_index_write_full() {
    local source_file="$1"
    local destination="$2"
    local formula commands_text command
    local -A seen
    local count=0

    : > "$destination" 2>/dev/null || return 1
    while IFS=: read -r formula commands_text; do
        formula="${formula%%\(*}"
        [[ -n "$formula" && -n "$commands_text" ]] || continue
        case "$formula" in
            *[!A-Za-z0-9@+_.-]*) continue ;;
        esac
        for command in ${(s: :)commands_text}; do
            [[ -n "$command" ]] || continue
            case "$command" in
                *'='*|*[$'\001'-$'\037'$'\177']*) continue ;;
            esac
            [[ -n "${seen[$command]:-}" ]] && continue
            seen[$command]="$formula"
            printf '%s=%s\n' "$command" "$formula" >> "$destination" || return 1
            (( count += 1 ))
        done
    done < "$source_file"
    (( count > 0 )) || return 1
    local sorted="${destination}.sorted"
    if ! LC_ALL=C sort -u "$destination" > "$sorted"; then
        rm -f "$sorted"
        return 1
    fi
    mv -f "$sorted" "$destination" || { rm -f "$sorted"; return 1; }
    return 0
}

# ------------------------------------------------------------
# _mdtk_index_file_is_safe
# ------------------------------------------------------------
# Description: reject missing, non-regular, unreadable, or oversized indexes.
# Parameters: $1 index file. Return: 0 safe; 1 unsafe.
# Example: _mdtk_index_file_is_safe "$file"
# ------------------------------------------------------------
_mdtk_index_file_is_safe() {
    local file="$1"
    [[ -f "$file" && -r "$file" ]] || return 1
    local size
    size=$(/usr/bin/stat -f '%z' "$file" 2>/dev/null) || return 1
    [[ "$size" == <-> ]] || return 1
    (( size > 0 && size <= MDTK_INDEX_MAX_BYTES ))
}

# ------------------------------------------------------------
# mdtk_index_build
# ------------------------------------------------------------
# Description
#   Rebuild the command index from Homebrew's complete executable metadata.
#   Atomically replace the previous index only after parsing succeeds.
# Parameters: none.
# Return: 0 on success; 1 if brew missing / IO failure.
# Example: mdtk_index_build
# ------------------------------------------------------------
mdtk_index_build() {
    if ! mdtk_backend_homebrew_available; then
        echo "Homebrew is not installed. mdtk index needs Homebrew." >&2
        return 1
    fi
    local file dir tmp source_file
    file="$(_mdtk_index_file)"
    dir="${file:a:h}"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || return 1
    fi
    tmp="${file}.tmp.$$"
    source_file=$(_mdtk_index_homebrew_executables_file) || return 1
    # `which-formula` owns refreshing this Homebrew database. Its miss is
    # expected; the side effect makes current metadata available to build.
    brew which-formula "__mdtk_index_refresh__" >/dev/null 2>&1 || true
    if [[ ! -s "$source_file" ]]; then
        echo "Homebrew executable metadata is unavailable. Run 'brew update' and try again." >&2
        return 1
    fi
    if ! _mdtk_index_write_full "$source_file" "$tmp"; then
        rm -f "$tmp"
        echo "Homebrew executable metadata is invalid; the existing MDTK index was kept." >&2
        return 1
    fi
    mv -f "$tmp" "$file" || { rm -f "$tmp"; return 1; }
    return 0
}

# ------------------------------------------------------------
# mdtk_index_lookup
# ------------------------------------------------------------
# Description: use exact binary lookup to print a formula, or nothing if absent.
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
    if ! _mdtk_index_file_is_safe "$file"; then
        return 1
    fi
    local line formula
    line=$(LC_ALL=C /usr/bin/look -t = -- "$cmd" "$file" 2>/dev/null | head -n 1)
    [[ "$line" == "${cmd}="* ]] || return 1
    formula="${line#*=}"
    [[ -n "$formula" ]] || return 1
    case "$formula" in
        *[!A-Za-z0-9@+_.-]*) return 1 ;;
    esac
    printf '%s\n' "$formula"
    return 0
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
