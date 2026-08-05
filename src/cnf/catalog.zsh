#!/usr/bin/env zsh
# ============================================================
# File:    src/cnf/catalog.zsh
# Purpose: Compile maintained popular-CLI catalogs into command indexes.
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================
#
# Description
#   Private CNF component that compiles a repository catalog without registry
#   or network access. Catalog records use rank|package|command... fields.
#   Lower numeric ranks win command collisions; equal ranks use the package's
#   byte order. The resulting command=package file is byte-sorted, bounded by
#   its backend limit, and atomically replaces an existing destination only
#   after the entire catalog validates.
#
# Dependencies
#   Sourced by index.zsh after its backend, path, validation, and size helpers
#   are defined.
#
# Public functions
#   mdtk_catalog_compile <backend> [destination]
#
# Return
#   0  compiled at least one record and atomically installed the destination.
#   1  unsupported backend, invalid/empty/oversized catalog, or I/O failure.
#
# Example
#   mdtk_catalog_compile npm "$HOME/.cache/mdtk/index/npm.idx"
# ============================================================

# ------------------------------------------------------------
# _mdtk_catalog_dir
# ------------------------------------------------------------
# Description: resolve maintained catalogs, with an isolated test override.
# Parameters: none. Return: 0; prints the catalog directory.
# Example: _mdtk_catalog_dir
# ------------------------------------------------------------
_mdtk_catalog_dir() {
    if [[ -n "${MDTK_CATALOG_ROOT:-}" ]]; then
        printf '%s\n' "${MDTK_CATALOG_ROOT:A}"
        return 0
    fi
    local self="${${(%):-%x}:A}"
    printf '%s/catalogs\n' "${self:h:h:h}"
}

# ------------------------------------------------------------
# _mdtk_catalog_file
# ------------------------------------------------------------
# Description: resolve a maintained catalog for a supported catalog backend.
# Parameters: $1 backend. Return: 0 and path; 1 unsupported.
# Example: _mdtk_catalog_file "pip"
# ------------------------------------------------------------
_mdtk_catalog_file() {
    local backend="$1"
    case "$backend" in
        pip|npm|cargo|conda)
            printf '%s/%s.catalog\n' "$(_mdtk_catalog_dir)" "$backend"
            ;;
        *) return 1 ;;
    esac
}

# ------------------------------------------------------------
# _mdtk_catalog_command_is_valid
# ------------------------------------------------------------
# Description: validate a curated executable key before associative storage.
# Parameters: $1 command. Return: 0 valid; 1 invalid.
# Example: _mdtk_catalog_command_is_valid "rg"
# ------------------------------------------------------------
_mdtk_catalog_command_is_valid() {
    local command="$1"
    _mdtk_index_command_is_valid "$command" || return 1
    case "$command" in
        -*|*'|'*|*[$' \t']*) return 1 ;;
    esac
    return 0
}

# ------------------------------------------------------------
# _mdtk_catalog_record_error
# ------------------------------------------------------------
# Description: print a stable validation error for a catalog record.
# Parameters: $1 backend; $2 line number; $3 reason.
# Return: 1.
# Example: _mdtk_catalog_record_error "npm" 3 "invalid rank"
# ------------------------------------------------------------
_mdtk_catalog_record_error() {
    local backend="$1"
    local line_number="$2"
    local reason="$3"
    printf 'Invalid %s catalog record at line %s: %s.\n' \
        "$backend" "$line_number" "$reason" >&2
    return 1
}

# ------------------------------------------------------------
# mdtk_catalog_compile
# ------------------------------------------------------------
# Description
#   Validate and compile one shipped popular-CLI catalog. Lower rank wins a
#   duplicate command; an equal-rank tie uses the byte-smaller package name.
#   The previous destination is preserved on every failure.
# Parameters
#   $1 backend: pip | npm | cargo | conda.
#   $2 optional destination; defaults to the backend's isolated index path.
# Return: 0 compiled and installed; 1 invalid input/backend or I/O failure.
# Example: mdtk_catalog_compile "npm"
# ------------------------------------------------------------
mdtk_catalog_compile() {
    local backend="$1"
    local destination="${2:-}"
    local source_file maximum destination_dir temporary sorted suffix
    local line rank package commands_text extra command
    local existing_rank existing_package numeric_rank
    local line_number=0
    local record_count=0
    local LC_ALL=C
    local -A selected_rank selected_package

    source_file=$(_mdtk_catalog_file "$backend") || return 1
    maximum=$(_mdtk_index_backend_max_bytes "$backend") || return 1
    if [[ -z "$destination" ]]; then
        destination=$(_mdtk_index_backend_file "$backend") || return 1
    fi
    _mdtk_index_file_is_safe "$source_file" "$maximum" || {
        printf 'Catalog is missing, empty, unreadable, or oversized: %s\n' \
            "$source_file" >&2
        return 1
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
        (( line_number += 1 ))
        [[ -n "$line" && "$line" != \#* ]] || continue
        if [[ "$line" == *'|'*'|'*'|'* ]]; then
            _mdtk_catalog_record_error "$backend" "$line_number" "expected three fields"
            return 1
        fi
        IFS='|' read -r rank package commands_text extra <<< "$line"
        if [[ -n "$extra" || -z "$rank" || -z "$package" || -z "$commands_text" ]]; then
            _mdtk_catalog_record_error "$backend" "$line_number" "expected three fields"
            return 1
        fi
        case "$rank" in
            *[!0-9]*)
                _mdtk_catalog_record_error "$backend" "$line_number" "invalid rank"
                return 1
                ;;
        esac
        if (( ${#rank} > 6 )); then
            _mdtk_catalog_record_error "$backend" "$line_number" "rank is out of range"
            return 1
        fi
        numeric_rank=$(( 10#$rank ))
        if (( numeric_rank < 1 || numeric_rank > 999999 )); then
            _mdtk_catalog_record_error "$backend" "$line_number" "rank is out of range"
            return 1
        fi
        if ! _mdtk_index_package_is_valid "$backend" "$package"; then
            _mdtk_catalog_record_error "$backend" "$line_number" "invalid package"
            return 1
        fi

        local command_count=0
        for command in ${(s: :)commands_text}; do
            [[ -n "$command" ]] || continue
            if ! _mdtk_catalog_command_is_valid "$command"; then
                _mdtk_catalog_record_error "$backend" "$line_number" "invalid command"
                return 1
            fi
            (( command_count += 1 ))
            existing_rank="${selected_rank[$command]:-}"
            existing_package="${selected_package[$command]:-}"
            if [[ -z "$existing_rank" ]] || (( numeric_rank < existing_rank )) || \
                { (( numeric_rank == existing_rank )) && [[ "$package" < "$existing_package" ]]; }; then
                selected_rank[$command]="$numeric_rank"
                selected_package[$command]="$package"
            fi
        done
        if (( command_count == 0 )); then
            _mdtk_catalog_record_error "$backend" "$line_number" "no commands"
            return 1
        fi
        (( record_count += 1 ))
    done < "$source_file"
    (( record_count > 0 && ${#selected_package} > 0 )) || return 1

    destination_dir="${destination:A:h}"
    mkdir -p "$destination_dir" || return 1
    suffix="XX"
    suffix="${suffix}${suffix}${suffix}"
    temporary=$(/usr/bin/mktemp "${destination}.tmp.${suffix}") || return 1
    sorted=$(/usr/bin/mktemp "${destination}.sorted.${suffix}") || {
        rm -f -- "$temporary"
        return 1
    }
    for command in "${(@k)selected_package}"; do
        printf '%s=%s\n' "$command" "${selected_package[$command]}" \
            >> "$temporary" || {
            rm -f -- "$temporary" "$sorted"
            return 1
        }
    done
    if ! LC_ALL=C /usr/bin/sort -u "$temporary" > "$sorted"; then
        rm -f -- "$temporary" "$sorted"
        return 1
    fi
    rm -f -- "$temporary"
    if ! _mdtk_index_file_is_safe "$sorted" "$maximum"; then
        rm -f -- "$sorted"
        return 1
    fi
    mv -f -- "$sorted" "$destination" || {
        rm -f -- "$sorted"
        return 1
    }
    return 0
}
