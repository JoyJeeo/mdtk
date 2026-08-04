#!/usr/bin/env zsh
# ============================================================
# File:    src/core/constants.zsh
# Purpose: Central home for project-level read-only constants.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   This file is the single place where project-wide `typeset -r`
#   constants live (default paths, identifiers, feature flags that
#   never change per-user). Concentrating them here enforces the
#   MASTER_PROMPT rule "Never hardcode paths" — callers source this
#   file and reference a named constant instead of sprinkling string
#   literals across modules.
#
#   Per .ai/STYLE_GUIDE.md, a `typeset -r` constant declared at file
#   scope is the ONE allowed exception to "no global variables".
#
# Why this file exists
#   - Avoid duplicated magic strings across modules.
#   - Make every default discoverable in one place.
#   - Keep modules free of cross-cutting configuration.
#
# Status
#   No cross-module constant is currently required. The file remains the
#   documented destination for future read-only project constants; keeping it
#   empty avoids inventing shared state or duplicating module-owned values.
# ============================================================
