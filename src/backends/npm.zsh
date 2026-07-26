#!/usr/bin/env zsh
# ============================================================
# File:    src/backends/npm.zsh
# Purpose: npm (Node) package-manager backend.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Wraps `npm` so the search and install modules can handle Node
#   packages uniformly with the other backends.
#
# Responsibility
#   - Search the npm registry for a package name.
#   - Map a CLI command to the npm package that provides it.
#   - Run (or recommend) an install via `npm install`.
#
# Direction (see .ai/ARCHITECTURE.md)
#   Called by: search, install modules.
#   Calls: `npm` (external). Never calls a module or the dispatcher.
#
# Expected interface (to be implemented at v0.4)
#   - mdtk_backend_npm_search <query>
#   - mdtk_backend_npm_provides <command>
#   - mdtk_backend_npm_install <package>
#
# Status
#   Phase 3 (source-tree design): comments only. No implementation.
#   Lands at v0.4 (.ai/ROADMAP.md).
# ============================================================
