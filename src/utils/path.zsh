#!/usr/bin/env zsh
# ============================================================
# File:    src/utils/path.zsh
# Purpose: Path-resolution helpers shared across modules.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Stateless helpers that resolve project- and user-level paths
#   without hardcoding them. This is the landing place for the
#   MASTER_PROMPT rule "Never hardcode paths".
#
# Responsibility
#   - Resolve the project root (where .shellspec / .ai live).
#   - Resolve the user's MDTK config/cache directory (e.g. under
#     $XDG_CONFIG_HOME/mdtk or $HOME/.config/mdtk), honoring XDG.
#   - Resolve the on-disk cache location used by the cache module.
#
# Why this is a util, not per-module
#   - config, cache, doctor, and install all need canonical paths;
#     duplicating resolution logic in each would violate
#     "Do not duplicate code" (MASTER_PROMPT) and
#     "No duplicated logic" (STYLE_GUIDE).
#   - utils are stateless and never call back into modules
#     (.ai/ARCHITECTURE.md).
#
# Expected interface (to be implemented when needed)
#   - mdtk_utils_path_root
#   - mdtk_utils_path_config
#   - mdtk_utils_path_cache
#
# Status
#   Phase 3 (source-tree design): comments only. No implementation.
# ============================================================
