# Changelog

All notable changes to MDTK are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Logger module (Issue #001).** `src/logger/logger.zsh` now implements structured logging: levels INFO / SUCCESS / WARNING / ERROR / DEBUG; color by default with `NO_COLOR` / `--no-color` support; `--quiet` (ERROR only); `--debug` / `MDTK_DEBUG=1` for DEBUG emission. Output format: `[LEVEL] message`. Public per-level functions (`mdtk_logger_info`, …) are available for other modules to adopt in their own issues. Tests in `tests/logger/logger_spec.sh`.

### Infrastructure
- Bootstrapped the project skeleton: `bin/mdtk` entry point, dispatcher, version constant, per-module stubs (`.ai/TASK.md` tracks the current issue — now #002 Config).
- Added `src/core/`, `src/utils/`, `src/backends/` layers as comments-only scaffolding (no implementation).
- Added `tests/` (shellspec) with a smoke suite for the skeleton; `make test` green.
- Added `install.zsh` (conda env check + shellspec + shellcheck bootstrap + symlink) and `Makefile`.

### Docs
- Added `.ai/` specs (MASTER_PROMPT, PRODUCT, ARCHITECTURE, STYLE_GUIDE, TESTING, DEVELOPMENT_RULES, ISSUE_PROCESS, DOD, REVIEW_PROMPT, ROADMAP, TASK).
- Added `docs/` (vision, faq, architecture, development) and `AGENTS.md`.
- Converted `TASK.md` from a single ad-hoc task into an issue backlog (#001 Logger current, #002–#004 queued); work now flows as one issue per module (`.ai/ISSUE_PROCESS.md`).
- Added `.ai/DOD.md` (Definition of Done) as the commit gate; wired into `ISSUE_PROCESS.md` and the contributor workflow.
- Added `.ai/REVIEW_PROMPT.md` (senior-reviewer prompt); merge now requires a review pass that does not write code, only finds BLOCKERs.
- Added `make lint` (parse with `zsh -n`, hard) and `make syntax`; shellcheck runs advisory in sh mode. `install.zsh` now installs shellcheck into the env.
