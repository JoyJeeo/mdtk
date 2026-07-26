#!/usr/bin/env zsh
# ============================================================
# File:    src/utils/color.zsh
# Purpose: ANSI color helpers shared across modules.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Stateless helpers for emitting (and suppressing) ANSI color codes.
#   Used by the Logger module and any module that prints user-facing
#   colored output.
#
# Responsibility
#   - Map a level name (info/success/warning/error/debug) to its ANSI
#     sequence.
#   - Honor the NO_COLOR convention (https://no-color.org/) and an
#     explicit no-color flag so color is never emitted when disabled.
#   - Provide a reset code helper.
#
# Why this is a util, not part of logger
#   - Multiple modules (doctor, install recommendation, etc.) will
#     want colored output without depending on the logger module.
#   - .ai/ARCHITECTURE.md: utils are a stateless library, not a module;
#     they have no dispatch function and never call back into modules.
#
# Expected interface (to be implemented when Logger lands)
#   - mdtk_utils_color_enable / mdtk_utils_color_disable
#   - mdtk_utils_color code <name>
#   - mdtk_utils_color_reset
#
# Status
#   Phase 3 (source-tree design): comments only. No implementation.
# ============================================================
