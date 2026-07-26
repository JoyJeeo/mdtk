# Changelog

All notable changes to MDTK are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Infrastructure
- Bootstrapped the project skeleton: `bin/mdtk` entry point, dispatcher, version constant, per-module stubs (`.ai/TASK.md` tracks the current issue — #001 Logger).
- Added `src/core/`, `src/utils/`, `src/backends/` layers as comments-only scaffolding (no implementation).
- Added `tests/` (shellspec) with a smoke suite for the skeleton; `make test` green.
- Added `install.zsh` (conda env check + shellspec bootstrap + symlink) and `Makefile`.

### Docs
- Added `.ai/` specs (MASTER_PROMPT, PRODUCT, ARCHITECTURE, STYLE_GUIDE, TESTING, DEVELOPMENT_RULES, ISSUE_PROCESS, DOD, ROADMAP, TASK).
- Added `docs/` (vision, faq, architecture, development) and `AGENTS.md`.
- Converted `TASK.md` from a single ad-hoc task into an issue backlog (#001 Logger current, #002–#004 queued); work now flows as one issue per module (`.ai/ISSUE_PROCESS.md`).
- Added `.ai/DOD.md` (Definition of Done) as the commit gate; wired into `ISSUE_PROCESS.md` and the contributor workflow.
- Added `make lint` (parse with `zsh -n`, hard) and `make syntax`; shellcheck runs advisory in sh mode. `install.zsh` now installs shellcheck into the env.
