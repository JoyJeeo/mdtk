# Changelog

All notable changes to MDTK are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Search engine (Issue #007).** `src/search/search.zsh` queries the Homebrew backend and prints matching formulae one per line. CLI: `mdtk search <query>`. Sources `utils/path` (library) and the homebrew backend (leaf, allowed); does NOT source other modules. Tests mock `brew` (`tests/search/search_spec.sh`).
- **Homebrew backend (Issue #006).** `src/backends/homebrew.zsh` wraps `brew` as a leaf backend (called by modules, never calls a module). API: `mdtk_backend_homebrew_available` (recognizes real command or test mock function), `_search <query>` (formula names, one/line), `_provides <command>` (same-name formula first, then alias scan), `_install <formula>`. Tests mock `brew` with a function override — no real network/installs (`tests/backends/homebrew_spec.sh`).
- **Command Dispatcher enhancement (Issue #005).** `src/dispatcher.zsh` now routes a `cnf` subcommand to the `src/cnf/cnf.zsh` module (lands for real in #010). Help text refreshed to describe landed modules and list `cnf`. No change to version/help/unknown behavior or the module routing contract.
- **Cache module (Issue #004).** `src/cache/cache.zsh` stores and retrieves named blobs under an XDG-aware cache dir (`$XDG_CACHE_HOME/mdtk`, fallback `$HOME/.cache/mdtk`). API: `mdtk_cache_get/set/clean` + CLI `mdtk cache {get|set|clean|list|path|help}`. Names restricted to `[a-z0-9_]+` (no path traversal). Sources `utils/path` (library). Tests in `tests/cache/cache_spec.sh` (isolated XDG).
- **Utils library (Issue #003).** `src/utils/{path,color,shell}.zsh` now implemented as a stateless shared library (not a module; no dispatch function, never calls back upward). path: `mdtk_utils_path_root/config/cache_dir/cache_file` (XDG-aware). color: `mdtk_utils_color_enabled/for/reset` (honors NO_COLOR and MDTK_NO_COLOR). shell: `mdtk_utils_shell_zsh_version/has_option/env_get` (set-u-safe env reading). Tests in `tests/utils/utils_spec.sh` (14 examples, isolated XDG/HOME).
- **Config module (Issue #002).** `src/config/config.zsh` reads/writes user preferences as a key=value file at an XDG-aware location (`$XDG_CONFIG_HOME/mdtk/config`, falling back to `$HOME/.config/mdtk/config`). Public API: `mdtk_config_get <key>`, `mdtk_config_set <key> <value>`, and CLI `mdtk config {get|set|list|path|help}`. Missing key returns 1; set overwrites or appends. Tests in `tests/config/config_spec.sh` (isolated XDG per example).
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
