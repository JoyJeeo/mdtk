#!/usr/bin/env zsh
# ============================================================
# File:    scripts/release-check.zsh
# Purpose: Run the complete offline MDTK production-release gate.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Runs parse checks, the full ShellSpec suite normally and with NO_COLOR,
#   checkout-local Smoke tests, and unfinished-marker scans over active runtime
#   files. It performs no network access and makes no repository changes.
#
# Parameters
#   None.
#
# Return
#   0 only when every release gate succeeds; otherwise the failing status.
#
# Example
#   conda activate mdtk
#   ./scripts/release-check.zsh
# ============================================================

set -eu
set -o pipefail

typeset -r MDTK_RELEASE_ROOT="${0:A:h:h}"
source "${MDTK_RELEASE_ROOT}/src/utils/color.zsh"

# Description: Print one release-gate step.
# Parameters: $1 message. Return: 0.
# Example: _mdtk_release_step "Running syntax checks."
_mdtk_release_step() {
    mdtk_utils_color_log "info" "$1"
}

# Description: Fail when active runtime files contain unfinished markers.
# Parameters: none. Return: 0 clean; 1 marker found.
# Example: _mdtk_release_check_markers
_mdtk_release_check_markers() {
    local -a targets=(
        src bin completions
        install.sh scripts/catalog-check.zsh scripts/install.sh
        scripts/dev-install.zsh scripts/mdtk.zsh
    )
    local findings=""
    local grep_status=0
    findings=$(git -C "$MDTK_RELEASE_ROOT" grep -n -E \
        '(^|[^A-Za-z0-9_])(TODO|FIXME|XXX)([^A-Za-z0-9_]|$)|not implemented|comments only|placeholder' -- \
        "${targets[@]}" 2>/dev/null) || grep_status=$?
    if (( grep_status > 1 )); then
        mdtk_utils_color_log "error" "Could not scan runtime files." >&2
        return "$grep_status"
    fi
    if [[ -n "$findings" ]]; then
        mdtk_utils_color_log "error" "Unfinished runtime markers found:" >&2
        print -r -- "$findings" >&2
        return 1
    fi
    return 0
}

# Description: Run every release gate in deterministic order.
# Parameters: none. Return: first failing status or 0.
# Example: _mdtk_release_main
_mdtk_release_main() {
    cd "$MDTK_RELEASE_ROOT"

    _mdtk_release_step "Checking Zsh syntax."
    make syntax

    _mdtk_release_step "Running the full test suite."
    shellspec

    _mdtk_release_step "Running the full test suite with NO_COLOR."
    NO_COLOR=1 shellspec

    _mdtk_release_step "Running checkout-local Smoke tests."
    make smoke

    _mdtk_release_step "Checking active runtime files for unfinished markers."
    _mdtk_release_check_markers

    mdtk_utils_color_log "success" "Release readiness checks passed."
}

_mdtk_release_main "$@"
