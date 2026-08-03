# shellcheck shell=sh
# ============================================================
# File:    tests/install/bootstrap_spec.sh
# Purpose: Tests for the local/remote top-level installer bootstrap.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   Uses fake git/uname commands and an isolated HOME/XDG data root.
#   Covers local delegation, default/tag installation, managed ref switching,
#   legacy migration, missing Git, invalid refs, unmarked targets, clone
#   failure, and whitespace paths.
#
# Run
#   make testone FILE=tests/install/bootstrap_spec.sh
# ============================================================

MDTK_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/install.sh"
_MDTK_BOOTSTRAP_TMP="$(mktemp -d)"

mdtk_bootstrap_setup() {
    rm -rf "${_MDTK_BOOTSTRAP_TMP}"
    mkdir -p "${_MDTK_BOOTSTRAP_TMP}/home"
    mkdir -p "${_MDTK_BOOTSTRAP_TMP}/fake-bin"
    mkdir -p "${_MDTK_BOOTSTRAP_TMP}/fixture/bin"
    mkdir -p "${_MDTK_BOOTSTRAP_TMP}/fixture/scripts"

    {
        echo '#!/usr/bin/env zsh'
        echo 'echo "fixture mdtk"'
    } > "${_MDTK_BOOTSTRAP_TMP}/fixture/bin/mdtk"
    chmod +x "${_MDTK_BOOTSTRAP_TMP}/fixture/bin/mdtk"
    {
        echo '#!/usr/bin/env zsh'
        echo 'echo "setup-run" >> "${0:A:h:h}/.setup-runs"'
        echo 'if [[ -f "${0:A:h:h}/.checked-out-ref" && "$(<"${0:A:h:h}/.checked-out-ref")" == "${MDTK_TEST_SETUP_FAIL_REF:-}" ]]; then return 1; fi'
        echo '[[ "${MDTK_TEST_SETUP_FAIL_FIRST:-0}" != "1" ]] || return 1'
        echo 'echo "fixture checkout installer ran"'
    } > "${_MDTK_BOOTSTRAP_TMP}/fixture/scripts/install.sh"

    {
        echo '#!/bin/sh'
        echo 'echo Darwin'
    } > "${_MDTK_BOOTSTRAP_TMP}/fake-bin/uname"
    chmod +x "${_MDTK_BOOTSTRAP_TMP}/fake-bin/uname"

    cat > "${_MDTK_BOOTSTRAP_TMP}/fake-bin/git" <<'EOF'
#!/bin/sh
if [ "${MDTK_TEST_GIT_FAIL:-0}" = "1" ]; then
    exit 1
fi
if [ "$1" = "ls-remote" ]; then
    printf 'a\trefs/tags/v0.1.0\n'
    printf 'b\trefs/tags/v0.1.2\n'
    printf 'c\trefs/tags/v0.1.1\n'
    exit 0
fi
if [ "$1" = "clone" ]; then
    previous=""
    selected_ref=""
    for arg do
        if [ "$previous" = "--branch" ]; then
            selected_ref="$arg"
        fi
        previous="$arg"
    done
    for last do :; done
    mkdir -p "$last"
    cp -R "${MDTK_TEST_FIXTURE}/." "$last"
    mkdir -p "$last/.git"
    echo "$selected_ref" > "$last/.cloned-ref"
    exit 0
fi
if [ "$1" = "-C" ]; then
    target="$2"
    if [ "$3" = "remote" ]; then
        echo "${MDTK_TEST_ORIGIN_URL:-https://github.com/JoyJeeo/mdtk.git}"
        exit 0
    fi
    if [ "$3" = "fetch" ]; then
        if [ "${MDTK_TEST_GIT_FAIL_FETCH:-0}" = "1" ]; then
            exit 1
        fi
        echo "$7" > "$target/.fetched-ref"
        exit 0
    fi
    if [ "$3" = "rev-parse" ]; then
        case "$4" in
            HEAD|"FETCH_HEAD^{commit}") echo "old-head-sha" ;;
            FETCH_HEAD) echo "annotated-tag-object-sha" ;;
            *) exit 1 ;;
        esac
        exit 0
    fi
    if [ "$3" = "checkout" ]; then
        if [ "${MDTK_TEST_GIT_FAIL_CHECKOUT:-0}" = "1" ]; then
            exit 1
        fi
        if [ "$5" = "FETCH_HEAD" ]; then
            cp "$target/.fetched-ref" "$target/.checked-out-ref"
            if [ "${MDTK_TEST_REF_METADATA_FAIL:-0}" = "1" ]; then
                rm -f "$target/.mdtk-managed-ref"
                mkdir "$target/.mdtk-managed-ref"
            fi
        else
            if [ -d "$target/.mdtk-managed-ref" ]; then
                rmdir "$target/.mdtk-managed-ref"
                echo "main" > "$target/.mdtk-managed-ref"
            fi
            echo "$5" > "$target/.checked-out-ref"
        fi
        exit 0
    fi
fi
exit 1
EOF
    chmod +x "${_MDTK_BOOTSTRAP_TMP}/fake-bin/git"

    export HOME="${_MDTK_BOOTSTRAP_TMP}/home"
    export XDG_DATA_HOME="${_MDTK_BOOTSTRAP_TMP}/xdg-data"
    export MDTK_TEST_FIXTURE="${_MDTK_BOOTSTRAP_TMP}/fixture"
    export PATH="${_MDTK_BOOTSTRAP_TMP}/fake-bin:/usr/bin:/bin"
    unset MDTK_TEST_GIT_FAIL
    unset MDTK_TEST_GIT_FAIL_FETCH
    unset MDTK_TEST_GIT_FAIL_CHECKOUT
    unset MDTK_TEST_SETUP_FAIL_REF
    unset MDTK_TEST_SETUP_FAIL_FIRST
    unset MDTK_TEST_REF_METADATA_FAIL
    unset MDTK_TEST_ORIGIN_URL
    unset MDTK_INSTALL_REPOSITORY_URL
    unset MDTK_INSTALL_REF
    unset MDTK_INSTALL_BRANCH
    export MDTK_INSTALL_CHANNEL=coder
}

_mdtk_bootstrap_run_remote() {
    zsh < "$MDTK_BOOTSTRAP"
}

_mdtk_bootstrap_remote_and_verify() {
    local output
    output="$(_mdtk_bootstrap_run_remote 2>&1)" || return 1
    echo "$output"
    local root="${XDG_DATA_HOME}/mdtk"
    [[ -x "${root}/bin/mdtk" ]] || return 1
    [[ "$(<"${root}/.mdtk-managed-install")" == "managed-by=mdtk-bootstrap-v1" ]] || return 1
    [[ "$(<"${root}/.mdtk-managed-ref")" == "${MDTK_INSTALL_REF:-${MDTK_INSTALL_BRANCH:-main}}" ]] || return 1
}

_mdtk_bootstrap_run_managed_file() {
    local root="${XDG_DATA_HOME}/mdtk"
    _mdtk_bootstrap_run_remote >/dev/null || return 1
    cp "$MDTK_BOOTSTRAP" "${root}/install.sh"
    MDTK_BOOTSTRAP_MANAGED_MODE=1 MDTK_INSTALL_REF="v0.1.1" \
        zsh "${root}/install.sh"
}

Describe 'top-level install bootstrap'
    BeforeEach 'mdtk_bootstrap_setup'

    It 'delegates when run from a local checkout'
        local checkout="${_MDTK_BOOTSTRAP_TMP}/local-checkout"
        mkdir -p "${checkout}/scripts" "${checkout}/bin"
        cp "$MDTK_BOOTSTRAP" "${checkout}/install.sh"
        cp "${_MDTK_BOOTSTRAP_TMP}/fixture/scripts/install.sh" "${checkout}/scripts/install.sh"
        cp "${_MDTK_BOOTSTRAP_TMP}/fixture/bin/mdtk" "${checkout}/bin/mdtk"
        chmod +x "${checkout}/bin/mdtk"
        When run zsh "${checkout}/install.sh"
        The status should be successful
        The output should include 'Installing from local checkout:'
        The output should include 'fixture checkout installer ran'
    End

    It 'installs from empty stdin arguments into the XDG data directory'
        When call _mdtk_bootstrap_remote_and_verify
        The status should be successful
        The output should include 'Downloading MDTK.'
        The output should include 'MDTK is ready.'
        The contents of file "${XDG_DATA_HOME}/mdtk/.cloned-ref" should equal 'main'
    End

    It 'selects the newest release tag for the stable channel'
        unset MDTK_INSTALL_CHANNEL
        When call _mdtk_bootstrap_remote_and_verify
        The output should include 'Downloading MDTK.'
        The contents of file "${XDG_DATA_HOME}/mdtk/.cloned-ref" should equal 'v0.1.2'
        The status should be successful
    End

    It 'selects main for the development channel'
        export MDTK_INSTALL_CHANNEL=coder
        When call _mdtk_bootstrap_remote_and_verify
        The contents of file "${XDG_DATA_HOME}/mdtk/.cloned-ref" should equal 'main'
        The output should include 'MDTK is ready.'
        The status should be successful
    End

    It 'installs a requested tag and records it'
        export MDTK_INSTALL_REF="v0.1.1"
        When call _mdtk_bootstrap_remote_and_verify
        The status should be successful
        The output should include 'MDTK is ready.'
        The contents of file "${XDG_DATA_HOME}/mdtk/.cloned-ref" should equal 'v0.1.1'
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'v0.1.1'
    End

    It 'switches an existing managed installation to another ref'
        export MDTK_INSTALL_REF="v0.1.1"
        _mdtk_bootstrap_run_remote >/dev/null
        export MDTK_INSTALL_REF="main"
        _mdtk_bootstrap_run_remote >/dev/null
        When call test "$(<"${XDG_DATA_HOME}/mdtk/.checked-out-ref")" = "main"
        The status should be successful
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'main'
    End

    It 'updates through managed mode when invoked from the checkout file'
        When call _mdtk_bootstrap_run_managed_file
        The output should include 'Installing ref v0.1.1'
        The output should not include 'Installing from local checkout:'
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'v0.1.1'
        The status should be successful
    End

    It 'skips setup when the requested ref already points to the current commit'
        export MDTK_INSTALL_CHANNEL=coder
        _mdtk_bootstrap_remote_and_verify >/dev/null
        local root="${XDG_DATA_HOME}/mdtk"
        local before="$(wc -l < "${root}/.setup-runs")"
        When call _mdtk_bootstrap_run_remote
        The output should include 'already installed; skipping setup'
        The contents of file "${root}/.setup-runs" should equal "setup-run"
        The status should be successful
    End

    It 'dereferences an unchanged annotated stable tag before skipping setup'
        unset MDTK_INSTALL_CHANNEL
        _mdtk_bootstrap_run_remote >/dev/null
        local root="${XDG_DATA_HOME}/mdtk"
        When call _mdtk_bootstrap_run_remote
        The output should include 'MDTK v0.1.2 is already installed; skipping setup.'
        The contents of file "${root}/.setup-runs" should equal "setup-run"
        The status should be successful
    End

    It 'migrates a managed checkout without ref metadata'
        _mdtk_bootstrap_run_remote >/dev/null
        rm -f "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref"
        When call _mdtk_bootstrap_run_remote
        The status should be successful
        The output should include 'Installing ref main'
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'main'
    End

    It 'keeps the deprecated branch override compatible'
        export MDTK_INSTALL_BRANCH="maintenance"
        When call _mdtk_bootstrap_remote_and_verify
        The status should be successful
        The output should include 'MDTK is ready.'
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'maintenance'
    End

    It 'refuses to update a managed checkout from a different origin'
        _mdtk_bootstrap_run_remote >/dev/null
        export MDTK_TEST_ORIGIN_URL="https://example.invalid/not-mdtk.git"
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The error should include 'origin does not match'
        The path "${XDG_DATA_HOME}/mdtk/.checked-out-ref" should not be exist
    End

    It 'rejects an unsafe ref before invoking Git clone'
        export MDTK_INSTALL_REF="--upload-pack=bad"
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The error should include 'Invalid install ref:'
        The path "${XDG_DATA_HOME}/mdtk" should not be exist
    End

    It 'reports a requested ref that Git cannot fetch'
        _mdtk_bootstrap_run_remote >/dev/null
        export MDTK_INSTALL_REF="v9.9.9"
        export MDTK_TEST_GIT_FAIL_FETCH=1
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The output should include 'Installing ref v9.9.9'
        The error should include 'Could not install ref: v9.9.9'
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'main'
    End

    It 'preserves ref metadata when checkout refuses local changes'
        _mdtk_bootstrap_run_remote >/dev/null
        export MDTK_INSTALL_REF="v0.1.1"
        export MDTK_TEST_GIT_FAIL_CHECKOUT=1
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The output should include 'Installing ref v0.1.1'
        The error should include 'Could not install ref: v0.1.1'
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'main'
    End

    It 'restores the previous checkout and ref when target setup fails'
        _mdtk_bootstrap_run_remote >/dev/null
        export MDTK_INSTALL_REF="v0.1.0"
        export MDTK_TEST_SETUP_FAIL_REF="v0.1.0"
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The output should include 'restoring the previous installation'
        The output should include 'fixture checkout installer ran'
        The error should include 'the previous installation was restored'
        The contents of file "${XDG_DATA_HOME}/mdtk/.checked-out-ref" should equal 'old-head-sha'
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'main'
    End

    It 'removes a new managed checkout when first setup fails'
        export MDTK_TEST_SETUP_FAIL_FIRST=1
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The output should include 'Running the MDTK installer.'
        The error should include 'incomplete installation was removed'
        The path "${XDG_DATA_HOME}/mdtk" should not be exist
    End

    It 'rolls back when target ref metadata cannot be committed'
        _mdtk_bootstrap_run_remote >/dev/null
        export MDTK_INSTALL_REF="v0.1.1"
        export MDTK_TEST_REF_METADATA_FAIL=1
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The output should include 'restoring the previous installation'
        The error should include 'Could not record ref v0.1.1'
        The contents of file "${XDG_DATA_HOME}/mdtk/.checked-out-ref" should equal 'old-head-sha'
        The contents of file "${XDG_DATA_HOME}/mdtk/.mdtk-managed-ref" should equal 'main'
    End

    It 'refuses to overwrite an unmarked existing directory'
        mkdir -p "${XDG_DATA_HOME}/mdtk"
        echo "keep" > "${XDG_DATA_HOME}/mdtk/sentinel"
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The error should include 'is not managed by MDTK'
        The path "${XDG_DATA_HOME}/mdtk/sentinel" should be file
    End

    It 'fails clearly when Git is unavailable'
        rm -f "${_MDTK_BOOTSTRAP_TMP}/fake-bin/git"
        export PATH="${_MDTK_BOOTSTRAP_TMP}/fake-bin:/bin"
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The error should include 'Git is required.'
    End

    It 'leaves no checkout behind when clone fails'
        export MDTK_TEST_GIT_FAIL=1
        When call _mdtk_bootstrap_run_remote
        The status should be failure
        The output should include 'Downloading MDTK.'
        The error should include 'Could not download MDTK.'
        The path "${XDG_DATA_HOME}/mdtk" should not be exist
    End

    It 'supports an XDG data path containing whitespace and Unicode'
        export XDG_DATA_HOME="${_MDTK_BOOTSTRAP_TMP}/数据 with space"
        When call _mdtk_bootstrap_remote_and_verify
        The status should be successful
        The output should include 'MDTK is ready.'
    End
End
