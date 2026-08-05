#!/usr/bin/env zsh
# ============================================================
# File:    scripts/catalog-check.zsh
# Purpose: Validate every maintained popular-CLI catalog offline.
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================
#
# Description
#   Compiles the shipped pip, npm, Cargo, and conda catalogs into an isolated
#   temporary directory, reports command counts and compiled byte sizes, and
#   removes every generated file. It does not update user indexes, invoke a
#   package manager, query a registry, or use the network.
#
# Parameters
#   None. `--help` prints usage without running validation.
#
# Return
#   0 when every catalog compiles within its backend limit; 1 otherwise.
#
# Example
#   conda activate mdtk
#   ./scripts/catalog-check.zsh
# ============================================================

set -eu
set -o pipefail

typeset -r MDTK_CATALOG_CHECK_ROOT="${0:A:h:h}"
source "${MDTK_CATALOG_CHECK_ROOT}/src/cnf/index.zsh"

# Description: print command usage.
# Parameters: none. Return: 0.
# Example: _mdtk_catalog_check_usage
_mdtk_catalog_check_usage() {
    printf 'Usage: ./scripts/catalog-check.zsh\n'
    printf 'Validate pip, npm, Cargo, and conda catalogs offline.\n'
}

# Description: remove only a generated compilation directory below TMPDIR.
# Parameters: $1 generated directory. Return: 0 removed/absent; 1 unsafe.
# Example: _mdtk_catalog_check_cleanup "$validation_dir"
_mdtk_catalog_check_cleanup() {
    local directory="${1:-}"
    local parent="${TMPDIR:-/tmp}"
    [[ -n "$directory" && -d "$directory" ]] || return 0
    [[ "${directory:t}" == mdtk-catalog-check.* ]] || return 1
    [[ "${directory:A:h}" == "${parent:A}" ]] || return 1
    rm -rf -- "$directory"
}

# Description: validate all maintained catalogs in fixed product order.
# Parameters: none. Return: 0 all valid; 1 one or more failed.
# Example: _mdtk_catalog_check_main
_mdtk_catalog_check_main() {
    local suffix="XX"
    local validation_dir=""
    local destination backend maximum commands bytes
    local total_commands=0
    local total_bytes=0
    local failed=0
    local -a backends=(pip npm cargo conda)

    suffix="${suffix}${suffix}${suffix}"
    validation_dir=$(/usr/bin/mktemp -d \
        "${TMPDIR:-/tmp}/mdtk-catalog-check.${suffix}") || return 1
    trap "_mdtk_catalog_check_cleanup ${(q)validation_dir}" EXIT
    for backend in "${backends[@]}"; do
        destination="${validation_dir}/${backend}.idx"
        maximum=$(_mdtk_index_backend_max_bytes "$backend") || {
            failed=1
            continue
        }
        if ! mdtk_catalog_compile "$backend" "$destination"; then
            printf '%s catalog: failed\n' "$backend" >&2
            failed=1
            continue
        fi
        commands="$(/usr/bin/wc -l < "$destination")"
        bytes="$(/usr/bin/wc -c < "$destination")"
        commands="${commands//[[:space:]]/}"
        bytes="${bytes//[[:space:]]/}"
        printf '%s catalog: %s commands, %s bytes (limit %s)\n' \
            "$backend" "$commands" "$bytes" "$maximum"
        (( total_commands += commands ))
        (( total_bytes += bytes ))
    done

    if (( failed != 0 )); then
        _mdtk_catalog_check_cleanup "$validation_dir"
        return 1
    fi
    printf 'All catalogs valid: %s commands, %s bytes compiled offline.\n' \
        "$total_commands" "$total_bytes"
    _mdtk_catalog_check_cleanup "$validation_dir"
}

case "${1:-}" in
    "")
        (( $# == 0 )) || { _mdtk_catalog_check_usage >&2; exit 1; }
        ;;
    --help|-h)
        (( $# == 1 )) || { _mdtk_catalog_check_usage >&2; exit 1; }
        _mdtk_catalog_check_usage
        exit 0
        ;;
    *)
        _mdtk_catalog_check_usage >&2
        exit 1
        ;;
esac

_mdtk_catalog_check_main
