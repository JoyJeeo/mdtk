#!/usr/bin/env zsh
# ============================================================
# File:    src/cnf/cnf.zsh
# Purpose: Stub for the command-not-found handler module (Issue #010).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Placeholder for the cnf module. Lands for real in Issue #010
#   (command_not_found_handler). Exists now so the dispatcher route
#   (#005) resolves. See .ai/TASK.md.
#
# Parameters: $@ ignored.
# Return: 1 (not implemented).
# ============================================================

mdtk_cnf_dispatch() {
    echo "command-not-found handler is not implemented yet."
    echo "See .ai/TASK.md (Issue #010)."
    return 1
}
