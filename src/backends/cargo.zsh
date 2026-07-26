#!/usr/bin/env zsh
# ============================================================
# File:    src/backends/cargo.zsh
# Purpose: cargo (Rust) package-manager backend.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Wraps `cargo` so the search and install modules can handle Rust
#   crates uniformly with the other backends.
#
# Responsibility
#   - Search crates.io for a crate name.
#   - Map a binary to the crate that ships it.
#   - Run (or recommend) an install via `cargo install`.
#
# Direction (see .ai/ARCHITECTURE.md)
#   Called by: search, install modules.
#   Calls: `cargo` (external). Never calls a module or the dispatcher.
#
# Expected interface (to be implemented at v0.4)
#   - mdtk_backend_cargo_search <query>
#   - mdtk_backend_cargo_provides <command>
#   - mdtk_backend_cargo_install <crate>
#
# Status
#   Phase 3 (source-tree design): comments only. No implementation.
#   Lands at v0.4 (.ai/ROADMAP.md).
# ============================================================
