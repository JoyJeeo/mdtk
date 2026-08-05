#!/usr/bin/env zsh
# ============================================================
# File:    src/cnf/index_stats.zsh
# Purpose: Bounded, privacy-preserving local index hit statistics.
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================
#
# Description
#   Records only epoch|hit-or-miss|backend-list. Command names and arguments
#   are never stored. The local file is bounded to 1 MiB; rotation retains its
#   10,000 most recent events. Reports support 7d, 30d, or retained history.
#
# Example
#   mdtk_index_stats_record hit "homebrew,cargo"
#   mdtk_index_stats_report 30d
# ============================================================

if (( ! ${+parameters[MDTK_INDEX_STATS_MAX_EVENTS]} )); then
    typeset -gr MDTK_INDEX_STATS_MAX_EVENTS=10000
fi
if (( ! ${+parameters[MDTK_INDEX_STATS_MAX_BYTES]} )); then
    typeset -gr MDTK_INDEX_STATS_MAX_BYTES=1048576
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
    [[ ! -L "$file" && ! -d "$file" ]] || return 1
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
