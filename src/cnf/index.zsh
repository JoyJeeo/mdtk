#!/usr/bin/env zsh
# ============================================================
# File:    src/cnf/index.zsh
# Purpose: Bounded multi-backend command-index storage and exact lookup.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Private CNF component that stores sorted command=package indexes below the
#   XDG cache. Homebrew's legacy command_index remains available while isolated
#   backend indexes live below mdtk/index. Exact lookups never invoke a package
#   manager or the network. It calls the Homebrew backend and utils/path, and is
#   sourced only by `cnf.zsh` in the same module.
#
#   Private CLI router (called only by `mdtk_cnf_dispatch`):
#       _mdtk_cnf_index_dispatch "$@"
#   Public functions:
#       mdtk_index_build        -> rebuild the index from brew
#       mdtk_index_lookup <cmd>                 -> legacy Homebrew lookup
#       mdtk_index_lookup_backend <cmd> <name>  -> selected backend lookup
#       mdtk_index_lookup_all <cmd>             -> backend=package matches
#
# Storage
#   $(mdtk_utils_path_cache_file command_index)  ; legacy Homebrew index
#   $(mdtk_utils_path_cache_dir)/index/*.idx     ; isolated backend indexes
#   $(mdtk_utils_path_cache_dir)/index/manifest  ; build metadata contract
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
typeset -ar MDTK_INDEX_BACKENDS=(homebrew pip npm cargo conda)

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
# _mdtk_index_dir
# ------------------------------------------------------------
# Description: resolve the isolated multi-backend index directory.
# Parameters: none. Return: 0; prints path.
# ------------------------------------------------------------
_mdtk_index_dir() {
    local cache_file
    cache_file=$(mdtk_utils_path_cache_file "index") || return 1
    printf '%s\n' "$cache_file"
}

# ------------------------------------------------------------
# _mdtk_index_manifest_file
# ------------------------------------------------------------
# Description: resolve the multi-backend build manifest path.
# Parameters: none. Return: 0; prints path.
# ------------------------------------------------------------
_mdtk_index_manifest_file() {
    printf '%s/manifest\n' "$(_mdtk_index_dir)"
}

# ------------------------------------------------------------
# _mdtk_index_backend_is_valid
# ------------------------------------------------------------
# Description: accept only product-defined backend identifiers.
# Parameters: $1 backend. Return: 0 supported; 1 unsupported.
# ------------------------------------------------------------
_mdtk_index_backend_is_valid() {
    case "$1" in
        homebrew|pip|npm|cargo|conda) return 0 ;;
        *) return 1 ;;
    esac
}

# ------------------------------------------------------------
# _mdtk_index_backend_max_bytes
# ------------------------------------------------------------
# Description: print the backend file limit; all limits total exactly 80 MiB.
# Parameters: $1 backend. Return: 0 supported; 1 unsupported.
# ------------------------------------------------------------
_mdtk_index_backend_max_bytes() {
    case "$1" in
        homebrew) printf '%s\n' 8388608 ;;
        pip)      printf '%s\n' 16777216 ;;
        npm)      printf '%s\n' 25165824 ;;
        cargo)    printf '%s\n' 12582912 ;;
        conda)    printf '%s\n' 20971520 ;;
        *) return 1 ;;
    esac
}

# ------------------------------------------------------------
# _mdtk_index_backend_file
# ------------------------------------------------------------
# Description: resolve a backend index without evaluating its name.
# Parameters: $1 backend. Return: 0 and path; 1 unsupported.
# ------------------------------------------------------------
_mdtk_index_backend_file() {
    local backend="$1"
    _mdtk_index_backend_is_valid "$backend" || return 1
    printf '%s/%s.idx\n' "$(_mdtk_index_dir)" "$backend"
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
# Parameters: $1 index file; $2 optional maximum bytes.
# Return: 0 safe; 1 unsafe.
# Example: _mdtk_index_file_is_safe "$file"
# ------------------------------------------------------------
_mdtk_index_file_is_safe() {
    local file="$1"
    local maximum="${2:-$MDTK_INDEX_MAX_BYTES}"
    case "$maximum" in
        ""|*[!0-9]*) return 1 ;;
    esac
    [[ -f "$file" && -r "$file" ]] || return 1
    local size
    size=$(/usr/bin/stat -f '%z' "$file" 2>/dev/null) || return 1
    case "$size" in
        ""|*[!0-9]*) return 1 ;;
    esac
    (( size > 0 && size <= maximum ))
}

# ------------------------------------------------------------
# _mdtk_index_command_is_valid
# ------------------------------------------------------------
# Description: reject empty keys, separators, and control characters.
# Parameters: $1 command. Return: 0 valid; 1 invalid.
# ------------------------------------------------------------
_mdtk_index_command_is_valid() {
    local command="$1"
    [[ -n "$command" ]] || return 1
    case "$command" in
        *'='*|*[$'\001'-$'\037'$'\177']*) return 1 ;;
    esac
    return 0
}

# ------------------------------------------------------------
# _mdtk_index_package_is_valid
# ------------------------------------------------------------
# Description: validate package names before printing cached data.
# Parameters: $1 backend; $2 package. Return: 0 valid; 1 invalid.
# ------------------------------------------------------------
_mdtk_index_package_is_valid() {
    local backend="$1"
    local package="$2"
    _mdtk_index_backend_is_valid "$backend" || return 1
    if [[ "$backend" == "npm" ]]; then
        [[ "$package" =~ '^(@[A-Za-z0-9._-]+/)?[A-Za-z0-9._-]+$' ]]
        return $?
    fi
    [[ "$package" =~ '^[A-Za-z0-9][A-Za-z0-9@+_.-]*$' ]]
}

# Private compiler component. It reuses the storage and validation contracts
# above and performs no package-manager or network calls.
source "${${(%):-%x}:A:h}/catalog.zsh"

# ------------------------------------------------------------
# _mdtk_index_lookup_file
# ------------------------------------------------------------
# Description: exact lookup in one already validated sorted index file.
# Parameters: $1 command; $2 backend; $3 file; $4 maximum bytes.
# Return: 0 and package on a valid match; 1 otherwise.
# ------------------------------------------------------------
_mdtk_index_lookup_file() {
    local command="$1"
    local backend="$2"
    local file="$3"
    local maximum="$4"
    _mdtk_index_command_is_valid "$command" || return 1
    _mdtk_index_file_is_safe "$file" "$maximum" || return 1

    local line package
    line=$(LC_ALL=C /usr/bin/look -t = -- "${command}=" "$file" 2>/dev/null | head -n 1)
    [[ "$line" == "${command}="* ]] || return 1
    package="${line#*=}"
    _mdtk_index_package_is_valid "$backend" "$package" || return 1
    printf '%s\n' "$package"
}

# ------------------------------------------------------------
# mdtk_index_lookup_backend
# ------------------------------------------------------------
# Description: query one isolated backend index, with Homebrew legacy fallback.
# Parameters: $1 command; $2 backend. Return: 0 hit; 1 absent/invalid.
# Example: mdtk_index_lookup_backend "eslint" "npm"
# ------------------------------------------------------------
mdtk_index_lookup_backend() {
    local command="$1"
    local backend="$2"
    local file maximum
    _mdtk_index_backend_is_valid "$backend" || return 1
    file=$(_mdtk_index_backend_file "$backend") || return 1
    maximum=$(_mdtk_index_backend_max_bytes "$backend") || return 1

    if [[ "$backend" == "homebrew" && ! -e "$file" ]]; then
        file=$(_mdtk_index_file) || return 1
        maximum=$MDTK_INDEX_MAX_BYTES
    fi
    _mdtk_index_lookup_file "$command" "$backend" "$file" "$maximum"
}

# ------------------------------------------------------------
# mdtk_index_lookup_all
# ------------------------------------------------------------
# Description: print every backend=package hit in fixed product order.
# Parameters: $1 command. Return: 0 if any backend matched; 1 otherwise.
# Example: mdtk_index_lookup_all "rg"
# ------------------------------------------------------------
mdtk_index_lookup_all() {
    local command="$1"
    local backend package
    local matched=1
    _mdtk_index_command_is_valid "$command" || return 1
    for backend in "${MDTK_INDEX_BACKENDS[@]}"; do
        package=$(mdtk_index_lookup_backend "$command" "$backend") || continue
        printf '%s=%s\n' "$backend" "$package"
        matched=0
    done
    return $matched
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
        mdtk_utils_color_log "error" "Homebrew is not installed. mdtk index needs Homebrew." >&2
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
        mdtk_utils_color_log "error" "Homebrew executable metadata is unavailable. Run 'brew update' and try again." >&2
        return 1
    fi
    if ! _mdtk_index_write_full "$source_file" "$tmp"; then
        rm -f "$tmp"
        mdtk_utils_color_log "error" "Homebrew executable metadata is invalid; the existing MDTK index was kept." >&2
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
    _mdtk_index_command_is_valid "$cmd" || return 1
    _mdtk_index_lookup_file "$cmd" "homebrew" "$(_mdtk_index_file)" "$MDTK_INDEX_MAX_BYTES"
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
  lookup <cmd>                    Print the legacy Homebrew formula.
  lookup --backend <name> <cmd>   Query one isolated backend index.
  lookup --all <cmd>              Print every backend=package match.
  path                            Print the legacy Homebrew index path.
  path --backend <name>           Print an isolated backend index path.
  path --manifest                 Print the build manifest path.
  help            Show this message.

Example:
  mdtk index build
  mdtk index lookup rg
  mdtk index lookup --backend npm eslint
  mdtk index lookup --all rg
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
            local mode="legacy"
            local backend=""
            local cmd=""
            case "$1" in
                --all)
                    mode="all"
                    cmd="$2"
                    shift 2 2>/dev/null
                    ;;
                --backend)
                    mode="backend"
                    backend="$2"
                    cmd="$3"
                    shift 3 2>/dev/null
                    ;;
                *)
                    cmd="$1"
                    shift 2>/dev/null
                    ;;
            esac
            if [[ -z "$cmd" || "$#" -ne 0 ]]; then
                _mdtk_index_usage
                return 1
            fi
            case "$mode" in
                legacy) mdtk_index_lookup "$cmd" ;;
                all) mdtk_index_lookup_all "$cmd" ;;
                backend)
                    if ! _mdtk_index_backend_is_valid "$backend"; then
                        mdtk_utils_color_log "error" "Unknown index backend: ${backend}" >&2
                        return 1
                    fi
                    mdtk_index_lookup_backend "$cmd" "$backend"
                    ;;
            esac
            return $?
            ;;
        path)
            case "$1" in
                "")
                    _mdtk_index_file
                    ;;
                --backend)
                    if [[ -z "$2" || -n "$3" ]] || ! _mdtk_index_backend_is_valid "$2"; then
                        _mdtk_index_usage
                        return 1
                    fi
                    _mdtk_index_backend_file "$2"
                    ;;
                --manifest)
                    if [[ -n "$2" ]]; then
                        _mdtk_index_usage
                        return 1
                    fi
                    _mdtk_index_manifest_file
                    ;;
                *)
                    _mdtk_index_usage
                    return 1
                    ;;
            esac
            return $?
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
            mdtk_utils_color_log "error" "Unknown index subcommand: ${sub}" >&2
            _mdtk_index_usage
            return 1
            ;;
    esac
}
