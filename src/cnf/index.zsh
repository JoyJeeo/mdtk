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
#       mdtk_index_build [name]                 -> rebuild all/one backend
#       mdtk_index_refresh [name]               -> manual refresh alias
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
#   - build/refresh: 0 if every selected backend and manifest succeeded;
#     1 after continuing past any selected backend failure.
#   - lookup: 0 if found (prints formula); 1 if not found.
#   - dispatch usage error: 1.
#
# Parameters (_mdtk_cnf_index_dispatch)
#   $1    subcommand: build | refresh | lookup | path | help
#   $@..  command (for lookup)
#
# Return
#   0  success.
#   1  usage error, brew missing, or not found.
#
# Example
#   mdtk index build
#   mdtk index refresh --backend npm
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
# _mdtk_index_secure_temp
# ------------------------------------------------------------
# Description: securely create a temporary file beside a destination.
# Parameters: $1 destination; $2 fixed purpose label.
# Return: 0 and path; 1 invalid label or creation failure.
# Example: _mdtk_index_secure_temp "$file" "build"
# ------------------------------------------------------------
_mdtk_index_secure_temp() {
    local destination="$1"
    local label="$2"
    local suffix="XX"
    [[ -n "$destination" && ! -d "$destination" ]] || return 1
    case "$label" in
        build|legacy|manifest|sort) ;;
        *) return 1 ;;
    esac
    suffix="${suffix}${suffix}${suffix}"
    /usr/bin/mktemp "${destination}.${label}.${suffix}"
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
    local sorted
    sorted=$(_mdtk_index_secure_temp "$destination" "sort") || return 1
    if ! LC_ALL=C /usr/bin/sort -u "$destination" > "$sorted"; then
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
# _mdtk_index_build_homebrew
# ------------------------------------------------------------
# Description
#   Rebuild isolated and legacy Homebrew indexes from complete executable
#   metadata. The isolated backend file is installed last so its old valid
#   version survives every preparation or legacy-install failure.
# Parameters: none.
# Return: 0 on success; 1 if brew/metadata/I/O fails.
# Example: _mdtk_index_build_homebrew
# ------------------------------------------------------------
_mdtk_index_build_homebrew() {
    if ! mdtk_backend_homebrew_available; then
        mdtk_utils_color_log "error" "Homebrew is not installed. mdtk index needs Homebrew." >&2
        return 1
    fi
    local file legacy_file index_dir legacy_dir temporary legacy_temporary
    local source_file maximum
    file=$(_mdtk_index_backend_file "homebrew") || return 1
    legacy_file=$(_mdtk_index_file) || return 1
    maximum=$(_mdtk_index_backend_max_bytes "homebrew") || return 1
    index_dir="${file:A:h}"
    legacy_dir="${legacy_file:A:h}"
    mkdir -p "$index_dir" "$legacy_dir" || return 1
    temporary=$(_mdtk_index_secure_temp "$file" "build") || return 1
    source_file=$(_mdtk_index_homebrew_executables_file) || {
        rm -f -- "$temporary"
        return 1
    }
    # `which-formula` owns refreshing this Homebrew database. Its miss is
    # expected; the side effect makes current metadata available to build.
    brew which-formula "__mdtk_index_refresh__" >/dev/null 2>&1 || true
    if [[ ! -s "$source_file" ]]; then
        rm -f -- "$temporary"
        mdtk_utils_color_log "error" "Homebrew executable metadata is unavailable. Run 'brew update' and try again." >&2
        return 1
    fi
    if ! _mdtk_index_write_full "$source_file" "$temporary" || \
        ! _mdtk_index_file_is_safe "$temporary" "$maximum"; then
        rm -f -- "$temporary"
        mdtk_utils_color_log "error" "Homebrew executable metadata is invalid; the existing MDTK index was kept." >&2
        return 1
    fi
    legacy_temporary=$(_mdtk_index_secure_temp "$legacy_file" "legacy") || {
        rm -f -- "$temporary"
        return 1
    }
    if ! /bin/cp "$temporary" "$legacy_temporary" || \
        ! /bin/mv -f "$legacy_temporary" "$legacy_file"; then
        rm -f -- "$temporary" "$legacy_temporary"
        return 1
    fi
    /bin/mv -f "$temporary" "$file" || {
        rm -f -- "$temporary"
        return 1
    }
    return 0
}

# ------------------------------------------------------------
# _mdtk_index_build_backend
# ------------------------------------------------------------
# Description: rebuild one backend through a fixed, injection-safe route.
# Parameters: $1 backend. Return: 0 rebuilt; 1 failed with old index preserved.
# Example: _mdtk_index_build_backend "npm"
# ------------------------------------------------------------
_mdtk_index_build_backend() {
    local backend="$1"
    case "$backend" in
        homebrew) _mdtk_index_build_homebrew ;;
        pip|npm|cargo|conda) mdtk_catalog_compile "$backend" ;;
        *) return 1 ;;
    esac
}

# ------------------------------------------------------------
# _mdtk_index_write_manifest
# ------------------------------------------------------------
# Description: atomically record one build selection and all backend statuses.
# Parameters: $1 selection; $@ backend=status records.
# Return: 0 installed a bounded manifest; 1 preserved the previous manifest.
# Example: _mdtk_index_write_manifest "npm" "npm=rebuilt"
# ------------------------------------------------------------
_mdtk_index_write_manifest() {
    local selection="$1"
    shift
    local manifest directory temporary generated_at entry backend backend_status
    local -A statuses
    manifest=$(_mdtk_index_manifest_file) || return 1
    [[ ! -d "$manifest" ]] || return 1
    directory="${manifest:A:h}"
    mkdir -p "$directory" || return 1
    temporary=$(_mdtk_index_secure_temp "$manifest" "manifest") || return 1
    generated_at=$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ') || {
        rm -f -- "$temporary"
        return 1
    }
    for entry in "$@"; do
        backend="${entry%%=*}"
        backend_status="${entry#*=}"
        _mdtk_index_backend_is_valid "$backend" || {
            rm -f -- "$temporary"
            return 1
        }
        case "$backend_status" in
            rebuilt|failed|not-selected) statuses[$backend]="$backend_status" ;;
            *) rm -f -- "$temporary"; return 1 ;;
        esac
    done
    {
        printf 'format=1\n'
        printf 'generated_at=%s\n' "$generated_at"
        printf 'selection=%s\n' "$selection"
        for backend in "${MDTK_INDEX_BACKENDS[@]}"; do
            printf '%s=%s\n' "$backend" "${statuses[$backend]:-not-selected}"
        done
    } > "$temporary" || {
        rm -f -- "$temporary"
        return 1
    }
    if ! _mdtk_index_file_is_safe "$temporary" 65536; then
        rm -f -- "$temporary"
        return 1
    fi
    /bin/mv -f "$temporary" "$manifest" || {
        rm -f -- "$temporary"
        return 1
    }
    return 0
}

# ------------------------------------------------------------
# mdtk_index_build
# ------------------------------------------------------------
# Description
#   Rebuild every backend in fixed product order, or one selected backend.
#   Continue after failures, preserve each failed backend's old index, write an
#   atomic manifest, and return nonzero if any selected operation failed.
# Parameters: $1 optional backend: homebrew | pip | npm | cargo | conda.
# Return: 0 all selected work succeeded; 1 invalid backend/partial failure.
# Example: mdtk_index_build "npm"
# ------------------------------------------------------------
mdtk_index_build() {
    (( $# <= 1 )) || return 1
    local selected="${1:-}"
    local backend selection
    local failed=0
    local -a targets manifest_statuses
    local -A statuses
    if [[ -n "$selected" ]] && ! _mdtk_index_backend_is_valid "$selected"; then
        return 1
    fi
    if [[ -n "$selected" ]]; then
        targets=("$selected")
        selection="$selected"
    else
        targets=("${MDTK_INDEX_BACKENDS[@]}")
        selection="all"
    fi
    for backend in "${MDTK_INDEX_BACKENDS[@]}"; do
        statuses[$backend]="not-selected"
    done
    for backend in "${targets[@]}"; do
        if _mdtk_index_build_backend "$backend"; then
            statuses[$backend]="rebuilt"
        else
            statuses[$backend]="failed"
            failed=1
            if [[ "$backend" != "homebrew" ]]; then
                mdtk_utils_color_log "error" \
                    "Could not rebuild ${backend}; its existing MDTK index was kept." >&2
            fi
        fi
    done
    for backend in "${MDTK_INDEX_BACKENDS[@]}"; do
        manifest_statuses+=("${backend}=${statuses[$backend]}")
    done
    if ! _mdtk_index_write_manifest "$selection" "${manifest_statuses[@]}"; then
        mdtk_utils_color_log "error" "Could not update the MDTK index manifest." >&2
        failed=1
    fi
    return $failed
}

# ------------------------------------------------------------
# mdtk_index_refresh
# ------------------------------------------------------------
# Description: explicit manual-refresh alias for mdtk_index_build.
# Parameters: $1 optional backend. Return: forwards mdtk_index_build status.
# Example: mdtk_index_refresh "cargo"
# ------------------------------------------------------------
mdtk_index_refresh() {
    (( $# <= 1 )) || return 1
    mdtk_index_build "${1:-}"
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
  build [--backend <name>]        Rebuild all local indexes, or one backend.
  refresh [--backend <name>]      Explicitly refresh all/one local indexes.
  lookup <cmd>                    Print the legacy Homebrew formula.
  lookup --backend <name> <cmd>   Query one isolated backend index.
  lookup --all <cmd>              Print every backend=package match.
  path                            Print the legacy Homebrew index path.
  path --backend <name>           Print an isolated backend index path.
  path --manifest                 Print the build manifest path.
  help            Show this message.

Example:
  mdtk index build
  mdtk index refresh --backend npm
  mdtk index lookup rg
  mdtk index lookup --backend npm eslint
  mdtk index lookup --all rg
EOF
}

# ------------------------------------------------------------
# _mdtk_cnf_index_dispatch
# ------------------------------------------------------------
# Description: CLI entry point. Routes build/refresh/lookup/path/help.
# Parameters: $1 subcommand, $@.. args.
# Return: 0 success; 1 usage/not-found/brew error.
# Example: _mdtk_cnf_index_dispatch lookup rg
# ------------------------------------------------------------
_mdtk_cnf_index_dispatch() {
    local sub="$1"
    shift 2>/dev/null
    case "$sub" in
        build|refresh)
            local selected=""
            case "$1" in
                "") ;;
                --backend)
                    selected="$2"
                    if [[ -z "$selected" || -n "$3" ]] || \
                        ! _mdtk_index_backend_is_valid "$selected"; then
                        _mdtk_index_usage
                        return 1
                    fi
                    ;;
                *)
                    _mdtk_index_usage
                    return 1
                    ;;
            esac
            if [[ "$sub" == "refresh" ]]; then
                mdtk_index_refresh "$selected"
            else
                mdtk_index_build "$selected"
            fi
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
