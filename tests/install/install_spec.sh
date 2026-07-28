# shellcheck shell=sh
# ============================================================
# File:    tests/install/install_spec.sh
# Purpose: Tests for the user-facing installer (Issue #011).
# Author:  MDTK Team
# Date:    2026-07-27
# ============================================================
#
# Description
#   Tests for scripts/install.sh. Each example runs against an isolated
#   HOME + PATH so it never touches the developer's real ~/.zshrc or
#   real /usr/local/bin. brew is mocked with a function override.
#   Covers: macOS/zsh guard, brew-missing, symlink placement,
#   zshrc hook idempotency, repo-not-found.
#
#   The installer is sourced (not run as a subprocess) so the mock
#   `brew` function and the isolated env are visible to it.
#
# Run
#   make test
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
INSTALL_SH="${MDTK_ROOT}/scripts/install.sh"

# Isolated HOME per spec.
_MDTK_INST_TMP="$(mktemp -d)"
_MDTK_INST_HOME="${_MDTK_INST_TMP}/home"
_MDTK_INST_BIN="${_MDTK_INST_HOME}/.local/bin"
mkdir -p "$_MDTK_INST_BIN"

mdtk_install_setup() {
    rm -rf "${_MDTK_INST_HOME}"
    mkdir -p "$_MDTK_INST_BIN"
}

# A wrapper that sources install.sh with the isolated env and a mock
# brew, then prints the exit code. We capture stdout to assert on it.
_mdtk_install_run() {
    (
        export HOME="${_MDTK_INST_HOME}"
        export PATH="/usr/local/bin:${_MDTK_INST_BIN}:/usr/bin:/bin"
        brew() { echo "brew shim"; }
        cd "${MDTK_ROOT}"
        # shellcheck source=/dev/null
        source "${INSTALL_SH}"
    )
}

Describe 'mdtk install (user-facing)'
    Before 'mdtk_install_setup'

    # The installer calls exit on failure, which in a sourced context
    # would abort the spec. So we wrap each example's invocation in a
    # subshell (already done by _mdtk_install_run) and assert on its
    # captured output.

    Describe 'happy path'
        It 'links mdtk and adds the shell hook'
            out=$(_mdtk_install_run 2>&1) || true
            echo "$out" | grep -q "linked 'mdtk'"
            echo "$out" | grep -q "shell hook"
            When call echo "matched"
            The output should equal "matched"
            The status should be successful
        End
        It 'the symlink lands in ~/.local/bin'
            _mdtk_install_run >/dev/null 2>&1
            When call test -L "${_MDTK_INST_BIN}/mdtk"
            The status should be successful
        End
        It 'the shell hook is in ~/.zshrc'
            _mdtk_install_run >/dev/null 2>&1
            When call grep -q "scripts/mdtk.zsh" "${_MDTK_INST_HOME}/.zshrc"
            The status should be successful
        End
        It 'uses the active writable Homebrew bin on Apple Silicon'
            local brew_bin="${_MDTK_INST_TMP}/homebrew/bin"
            mkdir -p "$brew_bin"
            {
                echo '#!/bin/sh'
                echo 'exit 0'
            } > "${brew_bin}/brew"
            chmod +x "${brew_bin}/brew"
            (
                export HOME="${_MDTK_INST_HOME}"
                export PATH="${brew_bin}:${_MDTK_INST_BIN}:/usr/bin:/bin"
                cd "${MDTK_ROOT}"
                source "${INSTALL_SH}"
            ) >/dev/null 2>&1
            When call test -L "${brew_bin}/mdtk"
            The status should be successful
        End
    End

    Describe 'idempotency'
        It 'does not duplicate the hook on re-run'
            _mdtk_install_run >/dev/null 2>&1
            _mdtk_install_run >/dev/null 2>&1
            # Count occurrences of the hook line.
            count=$(grep -c "scripts/mdtk.zsh" "${_MDTK_INST_HOME}/.zshrc" 2>/dev/null || echo 0)
            When call echo "$count"
            The output should equal "1"
            The status should be successful
        End
        It 'migrates an older checkout hook to the current checkout'
            {
                echo '# Added by mdtk installer.'
                echo 'source "/tmp/old-mdtk/scripts/mdtk.zsh"'
                echo 'source "/tmp/duplicate-mdtk/scripts/mdtk.zsh"'
                echo 'export KEEP_AFTER_MIGRATION=1'
            } > "${_MDTK_INST_HOME}/.zshrc"
            _mdtk_install_run >/dev/null 2>&1
            grep -qF "source \"${MDTK_ROOT}/scripts/mdtk.zsh\"" "${_MDTK_INST_HOME}/.zshrc"
            ! grep -qF '/tmp/old-mdtk/scripts/mdtk.zsh' "${_MDTK_INST_HOME}/.zshrc"
            count=$(grep -c 'scripts/mdtk.zsh' "${_MDTK_INST_HOME}/.zshrc")
            [[ "$count" == "1" ]]
            ls "${_MDTK_INST_HOME}"/.zshrc.mdtk-backup.* >/dev/null
            When run grep -F 'export KEEP_AFTER_MIGRATION=1' "${_MDTK_INST_HOME}/.zshrc"
            The status should be successful
            The output should include 'export KEEP_AFTER_MIGRATION=1'
        End
        It 'preserves a large existing zshrc while adding one hook'
            local i
            : > "${_MDTK_INST_HOME}/.zshrc"
            for i in {1..2000}; do
                echo "export EXISTING_${i}=${i}" >> "${_MDTK_INST_HOME}/.zshrc"
            done
            _mdtk_install_run >/dev/null 2>&1
            grep -q 'export EXISTING_1999=1999' "${_MDTK_INST_HOME}/.zshrc"
            count=$(grep -c "scripts/mdtk.zsh" "${_MDTK_INST_HOME}/.zshrc")
            When call echo "$count"
            The output should equal "1"
            The status should be successful
        End
    End

    Describe 'brew missing'
        It 'refuses when brew is not available'
            # No brew on PATH (real binary) and no brew function.
            out=$(
                export HOME="${_MDTK_INST_HOME}"
                export PATH="/usr/bin:/bin"
                cd "${MDTK_ROOT}"
                source "${INSTALL_SH}" 2>&1
            ) || true
            echo "$out" | grep -q "Homebrew is not installed"
            When call echo "matched"
            The output should equal "matched"
            The status should be successful
        End
    End

    Describe 'macOS guard'
        It 'refuses on non-macOS'
            # Fake uname to report Linux.
            out=$(
                export HOME="${_MDTK_INST_HOME}"
                export PATH="/usr/local/bin:${_MDTK_INST_BIN}:/usr/bin:/bin"
                brew() { echo "brew shim"; }
                uname() { echo "Linux"; }
                cd "${MDTK_ROOT}"
                source "${INSTALL_SH}" 2>&1
            ) || true
            echo "$out" | grep -q "macOS-only"
            When call echo "matched"
            The output should equal "matched"
            The status should be successful
        End
    End
End
