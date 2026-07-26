# shellcheck shell=sh
# ============================================================
# File:    spec/spec_helper.sh
# Purpose: Global helpers for the shellspec suite.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Loaded by every spec file via --require spec_helper.
#   Specs run under zsh (set in .shellspec via --shell zsh).
#   Keep it minimal; do not enable SH_WORD_SPLIT or strict -u
#   globally (shellspec internals do not like them).
#
# Parameters
#   None.
#
# Return
#   Always 0.
# ============================================================

# Minimum shellspec version we depend on.
spec_helper_precheck() {
    : minimum_version "${SHELLSPEC_VERSION%%[+-]*}"
}

spec_helper_loaded() {
    :
}

spec_helper_configure() {
    :
}
