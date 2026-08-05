#!/usr/bin/env zsh
# ============================================================
# File:    src/cnf/index_stats.zsh
# Purpose: Local aggregate statistics and opt-in detailed miss reports.
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================
#
# Description
#   Aggregate records contain only epoch|hit-or-miss|backend-list; command names
#   and arguments never enter that file. A separate command-level miss file is
#   disabled by default and records epoch|command only after explicit opt-in.
#   Both files are local, bounded, and never uploaded.
#
# Example
#   mdtk_index_stats_record hit "homebrew,cargo"
#   mdtk_index_stats_report 30d
#   mdtk_index_misses_enable
#   mdtk_index_misses_report 20
# ============================================================

if (( ! ${+parameters[MDTK_INDEX_STATS_MAX_EVENTS]} )); then
    typeset -gr MDTK_INDEX_STATS_MAX_EVENTS=10000
fi
if (( ! ${+parameters[MDTK_INDEX_STATS_MAX_BYTES]} )); then
    typeset -gr MDTK_INDEX_STATS_MAX_BYTES=1048576
fi
if (( ! ${+parameters[MDTK_INDEX_MISSES_MAX_BYTES]} )); then
    typeset -gr MDTK_INDEX_MISSES_MAX_BYTES=262144
fi
if (( ! ${+parameters[MDTK_INDEX_MISSES_KEEP_EVENTS]} )); then
    typeset -gr MDTK_INDEX_MISSES_KEEP_EVENTS=5000
fi

# Description: Resolve the aggregate event file below the index cache.
# Parameters: none. Return: 0 and path.
# Example: _mdtk_index_stats_file
_mdtk_index_stats_file() {
    printf '%s/stats\n' "$(_mdtk_index_dir)"
}

# Description: Validate a comma-separated, fixed-order backend list.
# Parameters: $1 list or - for a miss. Return: 0 valid; 1 invalid.
# Example: _mdtk_index_stats_backends_valid "homebrew,cargo"
_mdtk_index_stats_backends_valid() {
    local backends="$1"
    [[ "$backends" == "-" ]] && return 0
    local backend position previous=0 count=0
    for backend in ${(s:,:)backends}; do
        case "$backend" in
            homebrew) position=1 ;;
            pip) position=2 ;;
            npm) position=3 ;;
            cargo) position=4 ;;
            conda) position=5 ;;
            *) return 1 ;;
        esac
        (( position > previous )) || return 1
        previous=$position
        (( count += 1 ))
    done
    (( count > 0 ))
}

# Description: Best-effort append one anonymous event and rotate when needed.
# Parameters: $1 hit|miss; $2 fixed-order backends or -.
# Return: 0 recorded; 1 invalid or unavailable storage.
# Example: mdtk_index_stats_record "miss" "-"
mdtk_index_stats_record() {
    local outcome="$1" backends="$2"
    [[ "$outcome" == "hit" || "$outcome" == "miss" ]] || return 1
    _mdtk_index_stats_backends_valid "$backends" || return 1
    [[ "$outcome" == "hit" && "$backends" != "-" ]] || \
        [[ "$outcome" == "miss" && "$backends" == "-" ]] || return 1
    local file directory size temporary
    local -a file_size
    file=$(_mdtk_index_stats_file) || return 1
    [[ ! -L "$file" && ( ! -e "$file" || -f "$file" ) ]] || return 1
    directory="${file:A:h}"
    mkdir -p "$directory" || return 1
    zmodload zsh/datetime zsh/stat || return 1
    printf '%s|%s|%s\n' "$EPOCHSECONDS" "$outcome" "$backends" >> "$file" || return 1
    zstat -A file_size +size -- "$file" 2>/dev/null || return 1
    size="${file_size[1]}"
    (( size <= MDTK_INDEX_STATS_MAX_BYTES )) && return 0
    temporary=$(_mdtk_index_secure_temp "$file" "stats") || return 1
    /usr/bin/tail -n "$MDTK_INDEX_STATS_MAX_EVENTS" "$file" > "$temporary" || {
        rm -f -- "$temporary"
        return 1
    }
    /bin/mv -f "$temporary" "$file"
}

# Description: Print aggregate hit rate and per-backend hit contributions.
# Parameters: $1 optional 7d|30d|all (default 30d).
# Return: 0 report/missing file; 1 invalid period or unsafe storage.
# Example: mdtk_index_stats_report "7d"
mdtk_index_stats_report() {
    local period="${1:-30d}" seconds=0
    case "$period" in
        7d) seconds=604800 ;;
        30d) seconds=2592000 ;;
        all) seconds=0 ;;
        *) return 1 ;;
    esac
    local file line epoch outcome backends cutoff=0 backend
    local queries=0 hits=0 misses=0
    local -A backend_hits
    file=$(_mdtk_index_stats_file) || return 1
    zmodload zsh/datetime || return 1
    (( seconds > 0 )) && cutoff=$(( EPOCHSECONDS - seconds ))
    if [[ -e "$file" ]]; then
        [[ -f "$file" && -r "$file" && ! -L "$file" ]] || return 1
        if [[ -s "$file" ]] && \
            ! _mdtk_index_file_is_safe "$file" "$MDTK_INDEX_STATS_MAX_BYTES"; then
            return 1
        fi
        while IFS='|' read -r epoch outcome backends; do
            case "$epoch" in ""|*[!0-9]*) continue ;; esac
            (( epoch >= cutoff )) || continue
            _mdtk_index_stats_backends_valid "$backends" || continue
            case "$outcome" in
                hit)
                    [[ "$backends" != "-" ]] || continue
                    (( hits += 1, queries += 1 ))
                    for backend in ${(s:,:)backends}; do
                        (( backend_hits[$backend] += 1 ))
                    done
                    ;;
                miss)
                    [[ "$backends" == "-" ]] || continue
                    (( misses += 1, queries += 1 ))
                    ;;
            esac
        done < "$file"
    fi
    local rate=0.0
    (( queries > 0 )) && rate=$(( 100.0 * hits / queries ))
    printf 'Period: %s\nQueries: %d\nHits: %d\nMisses: %d\nHit rate: %.2f%%\n' \
        "$period" "$queries" "$hits" "$misses" "$rate"
    printf 'Backend hits:\n'
    for backend in "${MDTK_INDEX_BACKENDS[@]}"; do
        printf '  %s: %d\n' "$backend" "${backend_hits[$backend]:-0}"
    done
    return 0
}

# Description: Resolve the explicit detailed-miss opt-in marker.
# Parameters: none. Return: 0 and path.
# Example: _mdtk_index_misses_enabled_file
_mdtk_index_misses_enabled_file() {
    printf '%s/misses.enabled\n' "$(_mdtk_index_dir)"
}

# Description: Resolve detailed command-level miss storage.
# Parameters: none. Return: 0 and path.
# Example: _mdtk_index_misses_file
_mdtk_index_misses_file() {
    printf '%s/misses\n' "$(_mdtk_index_dir)"
}

# Description: Return whether detailed miss recording is explicitly enabled.
# Parameters: none. Return: 0 enabled; 1 disabled/unsafe.
# Example: mdtk_index_misses_enabled
mdtk_index_misses_enabled() {
    local marker
    marker=$(_mdtk_index_misses_enabled_file) || return 1
    [[ -f "$marker" && -r "$marker" && ! -L "$marker" ]] || return 1
    [[ "$(<"$marker")" == "enabled=1" ]]
}

# Description: Explicitly enable local command-name miss recording.
# Parameters: none. Return: 0 enabled; 1 storage failure.
# Example: mdtk_index_misses_enable
mdtk_index_misses_enable() {
    local marker directory temporary
    marker=$(_mdtk_index_misses_enabled_file) || return 1
    [[ ! -L "$marker" && ( ! -e "$marker" || -f "$marker" ) ]] || return 1
    directory="${marker:A:h}"
    mkdir -p "$directory" || return 1
    temporary=$(_mdtk_index_secure_temp "$marker" "misses") || return 1
    printf 'enabled=1\n' > "$temporary" || {
        rm -f -- "$temporary"
        return 1
    }
    /bin/chmod 600 "$temporary" || {
        rm -f -- "$temporary"
        return 1
    }
    /bin/mv -f "$temporary" "$marker"
}

# Description: Disable future detailed recording without deleting history.
# Parameters: none. Return: 0 disabled; 1 unsafe storage.
# Example: mdtk_index_misses_disable
mdtk_index_misses_disable() {
    local marker
    marker=$(_mdtk_index_misses_enabled_file) || return 1
    [[ ! -d "$marker" ]] || return 1
    rm -f -- "$marker"
}

# Description: Print enabled or disabled for script-friendly status checks.
# Parameters: none. Return: 0 and status text.
# Example: mdtk_index_misses_status
mdtk_index_misses_status() {
    if mdtk_index_misses_enabled; then
        printf 'enabled\n'
    else
        printf 'disabled\n'
    fi
}

# Description: Validate a detailed command key without storing arguments.
# Parameters: $1 command. Return: 0 safe; 1 empty/Unicode/large/malformed.
# Example: _mdtk_index_misses_command_valid "rg"
_mdtk_index_misses_command_valid() {
    local command="$1"
    _mdtk_index_searchable_command_is_valid "$command"
}

# Description: Best-effort record one command name only when explicitly enabled.
# Parameters: $1 missing command; arguments are intentionally unsupported.
# Return: 0 disabled/recorded; 1 invalid command or storage failure.
# Example: mdtk_index_misses_record "rg"
mdtk_index_misses_record() {
    (( $# == 1 )) || return 1
    mdtk_index_misses_enabled || return 0
    local command="$1"
    _mdtk_index_misses_command_valid "$command" || return 1
    local file directory temporary size
    local -a file_size
    file=$(_mdtk_index_misses_file) || return 1
    [[ ! -L "$file" && ( ! -e "$file" || -f "$file" ) ]] || return 1
    directory="${file:A:h}"
    mkdir -p "$directory" || return 1
    if [[ ! -e "$file" ]]; then
        temporary=$(_mdtk_index_secure_temp "$file" "misses") || return 1
        /bin/chmod 600 "$temporary" || {
            rm -f -- "$temporary"
            return 1
        }
        /bin/mv -f "$temporary" "$file" || {
            rm -f -- "$temporary"
            return 1
        }
    else
        /bin/chmod 600 "$file" || return 1
    fi
    zmodload zsh/datetime zsh/stat || return 1
    printf '%s|%s\n' "$EPOCHSECONDS" "$command" >> "$file" || return 1
    zstat -A file_size +size -- "$file" 2>/dev/null || return 1
    size="${file_size[1]}"
    (( size <= MDTK_INDEX_MISSES_MAX_BYTES )) && return 0
    temporary=$(_mdtk_index_secure_temp "$file" "misses") || return 1
    /usr/bin/tail -n "$MDTK_INDEX_MISSES_KEEP_EVENTS" "$file" > "$temporary" || {
        rm -f -- "$temporary"
        return 1
    }
    /bin/mv -f "$temporary" "$file"
}

# Description: Print top detailed misses by count, then command byte order.
# Parameters: $1 optional limit from 1 through 100 (default 20).
# Return: 0 report/missing data; 1 invalid limit or unsafe storage.
# Example: mdtk_index_misses_report 20
mdtk_index_misses_report() {
    local limit="${1:-20}"
    case "$limit" in ""|*[!0-9]*) return 1 ;; esac
    (( limit >= 1 && limit <= 100 )) || return 1
    local file line epoch command temporary sorted
    local -A counts
    file=$(_mdtk_index_misses_file) || return 1
    if [[ -e "$file" ]]; then
        [[ -f "$file" && -r "$file" && ! -L "$file" ]] || return 1
        if [[ -s "$file" ]] && \
            ! _mdtk_index_file_is_safe "$file" "$MDTK_INDEX_MISSES_MAX_BYTES"; then
            return 1
        fi
        while IFS='|' read -r epoch command; do
            case "$epoch" in ""|*[!0-9]*) continue ;; esac
            _mdtk_index_misses_command_valid "$command" || continue
            (( counts[$command] += 1 ))
        done < "$file"
    fi
    printf 'Detailed miss tracking: '
    mdtk_index_misses_status
    printf 'Limit: %d\nCount\tCommand\n' "$limit"
    (( ${#counts} > 0 )) || return 0
    temporary=$(_mdtk_index_secure_temp "$file" "miss-report") || return 1
    sorted=$(_mdtk_index_secure_temp "$file" "miss-report") || {
        rm -f -- "$temporary"
        return 1
    }
    for command in "${(@k)counts}"; do
        printf '%d|%s\n' "${counts[$command]}" "$command" >> "$temporary" || {
            rm -f -- "$temporary" "$sorted"
            return 1
        }
    done
    if ! LC_ALL=C /usr/bin/sort -t '|' -k1,1nr -k2,2 "$temporary" > "$sorted"; then
        rm -f -- "$temporary" "$sorted"
        return 1
    fi
    /usr/bin/head -n "$limit" "$sorted" | while IFS='|' read -r count command; do
        printf '%d\t%s\n' "$count" "$command"
    done
    local report_status=$?
    rm -f -- "$temporary" "$sorted"
    return $report_status
}

# Description: Remove detailed miss history without changing opt-in status.
# Parameters: none. Return: 0 reset; 1 unsafe target.
# Example: mdtk_index_misses_reset
mdtk_index_misses_reset() {
    local file
    file=$(_mdtk_index_misses_file) || return 1
    [[ ! -d "$file" ]] || return 1
    rm -f -- "$file"
}
