#!/usr/bin/env zsh
# ============================================================
# File:    src/version.zsh
# Purpose: Provide the MDTK version constant.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Declares the single version constant used across MDTK.
#   Sourced by the dispatcher and the entry point.
#
# Parameters
#   None.
#
# Return
#   Always 0. Sets the global constant MDTK_VERSION.
#
# Example
#   source src/version.zsh
#   echo "$MDTK_VERSION"
#   # => 0.4.0
# ============================================================

# Version follows the roadmap in .ai/ROADMAP.md.
# v0.4.0 — pip, cargo, conda, and npm package backends.
typeset -r MDTK_VERSION="0.4.0"
