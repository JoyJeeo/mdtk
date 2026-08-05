# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/index_stats_spec.sh
# Purpose: Tests for aggregate local index statistics (Issue #079).
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/dispatcher.zsh"

_MDTK_STATS_TMP="$(mktemp -d)"
export XDG_CACHE_HOME="${_MDTK_STATS_TMP}"

mdtk_stats_setup() {
    rm -rf "${_MDTK_STATS_TMP}/mdtk"
    mkdir -p "${_MDTK_STATS_TMP}/mdtk/index"
    mdtk_dispatch index help >/dev/null
}

_mdtk_stats_record_examples() {
    mdtk_index_stats_record hit 'homebrew,cargo'
    mdtk_index_stats_record hit 'npm'
    mdtk_index_stats_record miss '-'
}

_mdtk_stats_write_period_fixture() {
    zmodload zsh/datetime
    local now="$EPOCHSECONDS"
    printf '%s\n' \
        "$(( now - 3600 ))|hit|pip" \
        "$(( now - 10 * 86400 ))|miss|-" \
        "$(( now - 40 * 86400 ))|hit|conda" \
        > "${_MDTK_STATS_TMP}/mdtk/index/stats"
}

_mdtk_stats_rotate_large_file() {
    local file="${_MDTK_STATS_TMP}/mdtk/index/stats"
    yes '1|miss|-' | head -n 140000 > "$file"
    mdtk_index_stats_record hit npm || return 1
    local size
    size=$(/usr/bin/stat -f '%z' "$file") || return 1
    (( size <= MDTK_INDEX_STATS_MAX_BYTES ))
}

Describe 'aggregate local index statistics'
    Before 'mdtk_stats_setup'

    It 'reports an empty default 30-day window'
        When call mdtk_dispatch index stats
        The output should include 'Period: 30d'
        The output should include 'Queries: 0'
        The output should include 'Hit rate: 0.00%'
        The status should be successful
    End

    It 'reports hit rate and every backend contribution'
        _mdtk_stats_record_examples
        When call mdtk_dispatch index stats --period all
        The output should include 'Queries: 3'
        The output should include 'Hits: 2'
        The output should include 'Misses: 1'
        The output should include 'Hit rate: 66.67%'
        The output should include 'homebrew: 1'
        The output should include 'npm: 1'
        The output should include 'cargo: 1'
        The status should be successful
    End

    It 'filters the seven-day period'
        _mdtk_stats_write_period_fixture
        When call mdtk_dispatch index stats --period 7d
        The output should include 'Queries: 1'
        The output should include 'pip: 1'
        The output should include 'conda: 0'
        The status should be successful
    End

    It 'filters the default thirty-day period'
        _mdtk_stats_write_period_fixture
        When call mdtk_dispatch index stats
        The output should include 'Queries: 2'
        The output should include 'Misses: 1'
        The output should include 'conda: 0'
        The status should be successful
    End

    It 'reports all retained history'
        _mdtk_stats_write_period_fixture
        When call mdtk_dispatch index stats --period all
        The output should include 'Queries: 3'
        The output should include 'conda: 1'
        The status should be successful
    End

    It 'stores no command names or arguments'
        mdtk_index_stats_record hit 'homebrew,npm'
        When run cat "${_MDTK_STATS_TMP}/mdtk/index/stats"
        The output should match pattern '*|hit|homebrew,npm'
        The output should not include 'secret-command'
        The status should be successful
    End

    It 'records an anonymous multi-backend CNF hit'
        printf '%s\n' 'secret-command=brew-package' \
            > "${_MDTK_STATS_TMP}/mdtk/index/homebrew.idx"
        printf '%s\n' 'secret-command=npm-package' \
            > "${_MDTK_STATS_TMP}/mdtk/index/npm.idx"
        mdtk_dispatch cnf secret-command >/dev/null
        When run cat "${_MDTK_STATS_TMP}/mdtk/index/stats"
        The output should match pattern '*|hit|homebrew,npm'
        The output should not include 'secret-command'
        The status should be successful
    End

    It 'records an anonymous CNF miss'
        mdtk_dispatch cnf private-missing-command >/dev/null
        When run cat "${_MDTK_STATS_TMP}/mdtk/index/stats"
        The output should match pattern '*|miss|-'
        The output should not include 'private-missing-command'
        The status should be successful
    End

    It 'skips malformed retained records'
        printf '%s\n' 'invalid' '1|hit|unknown' > "${_MDTK_STATS_TMP}/mdtk/index/stats"
        When call mdtk_dispatch index stats --period all
        The output should include 'Queries: 0'
        The status should be successful
    End

    It 'treats an empty retained file as zero events'
        : > "${_MDTK_STATS_TMP}/mdtk/index/stats"
        When call mdtk_dispatch index stats
        The output should include 'Queries: 0'
        The status should be successful
    End

    It 'rejects oversized retained storage during reporting'
        /bin/dd if=/dev/zero of="${_MDTK_STATS_TMP}/mdtk/index/stats" \
            bs=1048576 count=2 2>/dev/null
        When call mdtk_dispatch index stats
        The error should include 'Invalid index statistics period or storage'
        The status should be failure
    End

    It 'rejects invalid event combinations'
        When call mdtk_index_stats_record miss npm
        The status should be failure
    End

    It 'rejects empty event input'
        When call mdtk_index_stats_record "" ""
        The status should be failure
    End

    It 'rejects an unknown reporting period'
        When call mdtk_dispatch index stats --period yearly
        The error should include 'Invalid index statistics period'
        The status should be failure
    End

    It 'rejects extra statistics arguments'
        When call mdtk_dispatch index stats --period 7d extra
        The output should include 'Usage:'
        The status should be failure
    End

    It 'refuses symlink event storage'
        echo protected > "${_MDTK_STATS_TMP}/protected"
        ln -s "${_MDTK_STATS_TMP}/protected" "${_MDTK_STATS_TMP}/mdtk/index/stats"
        When call mdtk_index_stats_record miss '-'
        The contents of file "${_MDTK_STATS_TMP}/protected" should equal 'protected'
        The status should be failure
    End

    It 'rotates oversized history to a bounded recent tail'
        When call _mdtk_stats_rotate_large_file
        The status should be successful
    End
End
