#!/usr/bin/env zsh
# ============================================================
# File:    src/utils/shell.zsh
# Purpose: zsh capability / compatibility helpers shared across modules.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Stateless helpers that detect zsh version and shell options so
#   modules and backends get stable behavior across zsh 5.x.
#
# Responsibility
#   - Detect the running zsh version (major/minor).
#   - Check whether a given shell option (e.g. pipefail) is available
#     before relying on it.
#   - Provide a safe, portable way to read optional env vars without
#     tripping `set -u` (which .ai/STYLE_GUIDE.md forbids in sourced
#     libraries).
#
# Why this is a util
#   - Backends (homebrew, pip, ...) will need to run external commands
#     and capture output; their pipe/exit handling must be consistent
#     and version-aware.
#   - Centralizing the detection avoids every module re-implementing
#     version checks.
#
# Expected interface (to be implemented when needed)
#   - mdtk_utils_shell_zsh_version
#   - mdtk_utils_shell_has_option <name>
#
# Status
#   Phase 3 (source-tree design): comments only. No implementation.
# ============================================================
