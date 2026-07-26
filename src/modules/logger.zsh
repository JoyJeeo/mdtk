#!/usr/bin/env zsh
# ============================================================
# File:    src/modules/logger.zsh
# Purpose: Stub for the Logger module (skeleton only).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Placeholder dispatch function for the logger subcommand.
#   The real implementation will land when .ai/TASK.md targets the
#   Logger module. See .ai/MASTER_PROMPT.md: never implement
#   features outside the current task.
#
# Parameters
#   $@    ignored for now
#
# Return
#   1  (not implemented)
#
# Example
#   mdtk logger --info "boot"
#   # => Logger module is not implemented yet. See .ai/TASK.md.
# ============================================================

mdtk_logger_dispatch() {
    echo "Logger module is not implemented yet."
    echo "See .ai/TASK.md for the current task."
    return 1
}
