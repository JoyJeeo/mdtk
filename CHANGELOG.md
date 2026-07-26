# Changelog

All notable changes to MDTK are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Infrastructure
- Bootstrapped the project skeleton: `bin/mdtk` entry point, dispatcher, version constant, per-module stubs (`.ai/TASK.md` tracks the current task — Logger).
- Added `src/core/`, `src/utils/`, `src/backends/` layers as comments-only scaffolding (no implementation).
- Added `tests/` (shellspec) with a smoke suite for the skeleton; `make test` green.
- Added `install.zsh` (conda env check + shellspec bootstrap + symlink) and `Makefile`.

### Docs
- Added `.ai/` specs (MASTER_PROMPT, PRODUCT, ARCHITECTURE, STYLE_GUIDE, TESTING, DEVELOPMENT_RULES, ROADMAP, TASK).
- Added `docs/` (vision, faq, architecture, development) and `AGENTS.md`.
