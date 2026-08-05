# shellcheck shell=sh
# ============================================================
# File:    tests/cnf/index_misses_spec.sh
# Purpose: Tests for opt-in detailed index misses (Issue #080).
# Author:  MDTK Team
# Date:    2026-08-05
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/dispatcher.zsh"

_MDTK_MISSES_TMP="$(mktemp -d)"
export XDG_CACHE_HOME="${_MDTK_MISSES_TMP}"

mdtk_misses_setup() {
    rm -rf "${_MDTK_MISSES_TMP}/mdtk" "${_MDTK_MISSES_TMP}/protected"
    mkdir -p "${_MDTK_MISSES_TMP}/mdtk/index"
    mdtk_dispatch index help >/dev/null
}

_mdtk_misses_record_fixture() {
    mdtk_index_misses_enable || return 1
    mdtk_index_misses_record zulu
    mdtk_index_misses_record alpha
    mdtk_index_misses_record zulu
    mdtk_index_misses_record beta
    mdtk_index_misses_record alpha
    mdtk_index_misses_record zulu
}

_mdtk_misses_large_command() {
    local command="${(l:256::x:)}"
    mdtk_index_misses_record "$command"
}

_mdtk_misses_rotate_large_file() {
    local file="${_MDTK_MISSES_TMP}/mdtk/index/misses"
    mdtk_index_misses_enable || return 1
    yes '1|missing-tool' | head -n 30000 > "$file"
    mdtk_index_misses_record newest-tool || return 1
    local size
    size=$(/usr/bin/stat -f '%z' "$file") || return 1
    (( size <= MDTK_INDEX_MISSES_MAX_BYTES ))
}

Describe 'opt-in detailed index misses'
    Before 'mdtk_misses_setup'

    Describe 'tracking control'
        It 'is disabled by default'
            When call mdtk_dispatch index miss-tracking status
            The output should equal 'disabled'
            The status should be successful
        End

        It 'does not create detailed storage for default CNF misses'
            mdtk_dispatch cnf private-command --secret >/dev/null
            When run test -e "${_MDTK_MISSES_TMP}/mdtk/index/misses"
            The status should be failure
        End

        It 'explicitly enables tracking with a private marker'
            mdtk_dispatch index miss-tracking enable
            When run /usr/bin/stat -f '%Lp' "${_MDTK_MISSES_TMP}/mdtk/index/misses.enabled"
            The output should equal '600'
            The status should be successful
        End

        It 'reports enabled status after enabling twice'
            mdtk_dispatch index miss-tracking enable
            mdtk_dispatch index miss-tracking enable
            When call mdtk_dispatch index miss-tracking status
            The output should equal 'enabled'
            The status should be successful
        End

        It 'disables future recording without deleting history'
            mdtk_index_misses_enable
            mdtk_index_misses_record first-tool
            mdtk_dispatch index miss-tracking disable
            mdtk_index_misses_record second-tool
            When run cat "${_MDTK_MISSES_TMP}/mdtk/index/misses"
            The output should include 'first-tool'
            The output should not include 'second-tool'
            The status should be successful
        End

        It 'rejects unsafe opt-in marker storage'
            echo protected > "${_MDTK_MISSES_TMP}/protected"
            ln -s "${_MDTK_MISSES_TMP}/protected" \
                "${_MDTK_MISSES_TMP}/mdtk/index/misses.enabled"
            When call mdtk_dispatch index miss-tracking enable
            The contents of file "${_MDTK_MISSES_TMP}/protected" should equal 'protected'
            The status should be failure
        End
    End

    Describe 'recording and privacy'
        It 'records only the command name after explicit opt-in'
            mdtk_index_misses_enable
            mdtk_dispatch cnf private-command --secret-token >/dev/null
            When run cat "${_MDTK_MISSES_TMP}/mdtk/index/misses"
            The output should match pattern '*|private-command'
            The output should not include 'secret-token'
            The status should be successful
        End

        It 'stores detailed command history with private permissions'
            mdtk_index_misses_enable
            mdtk_index_misses_record private-command
            When run /usr/bin/stat -f '%Lp' "${_MDTK_MISSES_TMP}/mdtk/index/misses"
            The output should equal '600'
            The status should be successful
        End

        It 'rejects empty detailed command input when enabled'
            mdtk_index_misses_enable
            When call mdtk_index_misses_record ''
            The status should be failure
        End

        It 'rejects Unicode detailed command keys safely'
            mdtk_index_misses_enable
            When call mdtk_index_misses_record '工具'
            The status should be failure
        End

        It 'rejects oversized detailed command keys safely'
            mdtk_index_misses_enable
            When call _mdtk_misses_large_command
            The status should be failure
        End

        It 'rejects attempts to record arguments'
            mdtk_index_misses_enable
            When call mdtk_index_misses_record command argument
            The status should be failure
        End

        It 'refuses symlink detailed storage'
            mdtk_index_misses_enable
            echo protected > "${_MDTK_MISSES_TMP}/protected"
            ln -s "${_MDTK_MISSES_TMP}/protected" \
                "${_MDTK_MISSES_TMP}/mdtk/index/misses"
            When call mdtk_index_misses_record tool
            The contents of file "${_MDTK_MISSES_TMP}/protected" should equal 'protected'
            The status should be failure
        End

        It 'rotates oversized detailed history to a bounded recent tail'
            When call _mdtk_misses_rotate_large_file
            The status should be successful
        End
    End

    Describe 'report and reset'
        It 'reports counts in descending order with byte-order ties'
            _mdtk_misses_record_fixture
            When call mdtk_dispatch index miss-report
            The output should include 'Detailed miss tracking: enabled'
            The line 4 of output should equal $'3\tzulu'
            The line 5 of output should equal $'2\talpha'
            The line 6 of output should equal $'1\tbeta'
            The status should be successful
        End

        It 'limits the number of reported commands'
            _mdtk_misses_record_fixture
            When call mdtk_dispatch index miss-report --limit 2
            The output should include 'Limit: 2'
            The line 5 of output should equal $'2\talpha'
            The line 6 of output should be undefined
            The status should be successful
        End

        It 'reports no commands for missing history'
            When call mdtk_dispatch index miss-report
            The output should include 'Detailed miss tracking: disabled'
            The output should include $'Count\tCommand'
            The status should be successful
        End

        It 'skips malformed retained records'
            printf '%s\n' 'invalid' '1|工具' '2|valid-tool' \
                > "${_MDTK_MISSES_TMP}/mdtk/index/misses"
            When call mdtk_dispatch index miss-report
            The output should include $'1\tvalid-tool'
            The output should not include '工具'
            The status should be successful
        End

        It 'rejects invalid report limits'
            When call mdtk_dispatch index miss-report --limit 101
            The error should include 'Invalid detailed miss limit'
            The status should be failure
        End

        It 'rejects a missing report limit'
            When call mdtk_dispatch index miss-report --limit
            The output should include 'Usage:'
            The status should be failure
        End

        It 'rejects oversized retained detailed storage'
            /bin/dd if=/dev/zero of="${_MDTK_MISSES_TMP}/mdtk/index/misses" \
                bs=262145 count=1 2>/dev/null
            When call mdtk_dispatch index miss-report
            The error should include 'Invalid detailed miss limit or storage'
            The status should be failure
        End

        It 'resets history without changing enabled status'
            _mdtk_misses_record_fixture
            When call mdtk_dispatch index miss-reset
            The path "${_MDTK_MISSES_TMP}/mdtk/index/misses" should not be exist
            The path "${_MDTK_MISSES_TMP}/mdtk/index/misses.enabled" should be file
            The status should be successful
        End

        It 'rejects extra reset arguments'
            When call mdtk_dispatch index miss-reset extra
            The output should include 'Usage:'
            The status should be failure
        End
    End
End
