# Changelog

All notable changes to MDTK are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.5] - 2026-08-04

### Added
- **Shared colored log labels (Issue #042).** Added a no-icon, fixed-width formatter for INFO, SUCCESS, WARNING, ERROR, and DEBUG output so modules can share consistent level colors while preserving ANSI-free `NO_COLOR` output.

### Changed
- **Logger colored presentation (Issue #043).** Logger output now uses the shared no-icon formatter, with consistently colored and aligned level labels while preserving quiet, debug, and no-color modes.
- **Installer colored presentation (Issue #044).** Remote and checkout installers now use aligned INFO, SUCCESS, WARNING, and ERROR labels with consistent colors and ANSI-free `NO_COLOR` output; the former `OK` and `WARN` abbreviations were removed.
- **Update colored presentation (Issue #045).** Managed-update status and errors now use the shared aligned level colors while preserving stderr routing, option behavior, and ANSI-free `NO_COLOR` output.
- **CNF/index colored presentation (Issue #046).** Command recommendations and offline misses now use aligned SUCCESS/INFO/WARNING labels, while index errors use ERROR; exact formula lookup remains silent, plain, and script-friendly.
- **Install-recommendation colored presentation (Issue #047).** Direct install recommendations now match CNF's SUCCESS/INFO/WARNING colors, and missing Homebrew errors use the shared ERROR style without changing recommendation-only behavior.
- **Search colored errors (Issue #048).** Search prerequisite errors now use the shared ERROR color while formula and cask result lines remain unchanged for piping and parsing.
- **Uninstall colored presentation (Issue #049).** Removal plans, cancellation, safety errors, and completion now use aligned INFO/WARNING/ERROR/SUCCESS labels without changing confirmation prompts, dry-run safety, or `.zshrc` content.
- **Dispatcher colored errors (Issue #050).** Unknown commands and their recovery hint now use aligned ERROR/INFO colors while help, version, normal routing, and stdout behavior remain unchanged.
- **Developer-installer colored presentation (Issue #051).** The conda developer bootstrap now uses aligned semantic colors for environment, dependency, warning, error, and completion output while preserving isolated tooling and symlink behavior.
- **Config colored errors (Issue #052).** Unknown config subcommands now use the shared ERROR color while stored values, list output, and paths remain plain and script-friendly.
- **Cache colored errors (Issue #053).** Unknown cache subcommands now use the shared ERROR color while cached values, entry lists, and cache paths remain plain and script-friendly.
- **Homebrew backend colored errors (Issue #054).** The backend's missing-Homebrew error now uses the shared ERROR color while package results and delegated install output remain unchanged.
- **Colored-output documentation (Issue #055).** README and code examples now consistently describe aligned, no-icon status colors and clarify that command data remains plain for piping.

## [0.1.4] - 2026-08-03

### Fixed
- **Annotated-tag reinstall detection (Issue #040).** Managed reinstall checks now dereference annotated tags to their commit before comparing with `HEAD`, so unchanged stable versions correctly skip setup.

## [0.1.3] - 2026-08-03

### Added
- **Coder channel naming (Issue #038).** Developer curl installs now use the clearer `MDTK_INSTALL_CHANNEL=coder` value while `mdtk update --coder` remains the update command.
- **Stable and coder install channels (Issue #037).** Remote installs and ordinary updates now select the newest semantic release tag by default; developers can explicitly select `main` with `MDTK_INSTALL_CHANNEL=coder` or `mdtk update --coder`. Reinstalling an unchanged managed ref skips setup.

## [0.1.2] - 2026-07-29

### Added
- **Full offline Homebrew command index (Issue #033).** `mdtk index build` now uses Homebrew's complete executable metadata, so commands provided by uninstalled formulae can be recommended from the XDG cache. Index replacement is atomic, malformed or unavailable metadata preserves the previous cache, and command-not-found misses no longer wait for Homebrew or claim that a locally absent result cannot be installed.

### Fixed
- **Exact binary index prefix matching (Issue #035).** Binary command lookup now searches with the complete `command=` key, so an exact command such as `fd` is found even when lexically earlier prefix neighbors such as `fd2c` exist in the full index.
- **Fast command-index lookup (Issue #034).** Full command indexes are now written in deterministic byte order and queried with exact binary lookup instead of a full-file scan. Missing, malformed, unreadable, empty, or indexes above 8 MiB fail fast without invoking Homebrew or the network; 20,000-record hit and miss paths have a two-second regression bound.
- **Short command fallback guard (Issue #032).** One- and two-character command names still use the fast local index, but index misses now skip broad automatic Homebrew fallback and print an explicit manual-search command, preventing ambiguous terms such as `ip` from blocking the interactive shell for minutes.

## [0.1.1] - 2026-07-29

### Fixed
- **Transactional managed ref activation (Issue #030).** Managed ref metadata is now committed only after target setup succeeds. Failed updates restore the previous HEAD and ref metadata and rerun the previous setup; failed first installs remove their incomplete managed checkout.
- **Full command-not-found input classification (Issue #027).** The zsh hook now forwards the complete missing-command field so CNF can distinguish command-shaped invocations from pasted headings, Markdown/list content, sentence-like prose, and oversized text before any cache or Homebrew I/O, while preserving options, paths, assignments, short arguments, and CJK arguments.
- **Command-not-found pasted-text guard (Issue #026).** Obvious non-command tokens such as numeric section headings and pasted list markers now return immediately instead of triggering slow Homebrew fallback searches; common punctuated executable names remain searchable.
- **Uninstall hook cleanup at end of zshrc (Issue #025).** Uninstall now completes when its managed shell hook is the final `.zshrc` entry, instead of stopping before cache, configuration, and managed-source cleanup.
- **Silent command-index build (Issue #024).** Command-index builds no longer print stale Homebrew formula JSON when processing multiple installed formulae; index contents and lookup behavior are unchanged.
- **Homebrew-bin install fallback (Issue #023).** The checkout installer now prefers the writable, on-PATH directory containing the active Homebrew binary, allowing real Apple Silicon installations to use `/opt/homebrew/bin` when `/usr/local/bin` and `~/.local/bin` are unsuitable.
- **Planning metadata synchronization (Issue #020).** Reconciled the authoritative PRODUCT, ROADMAP, and TASK metadata with the shipped v0.1 Homebrew functionality and the queued v0.2 Doctor milestone; added cross-document regression specs.
- **Human documentation state synchronization (Issue #019).** Updated runtime prerequisites, implemented/stub module status, Homebrew backend wording, install behavior, and test instructions across the maintained README/docs; historical planning transcripts are now labeled as non-authoritative.
- **Developer bootstrap ShellCheck directive cleanup (Issue #018).** Reworded a bootstrap comment that ShellCheck misread as a malformed directive and added a repository-lint regression spec.
- **CNF command-index architecture boundary (Issue #017).** The command index is now an explicit private component of CNF. The public `mdtk index` alias routes through CNF's sole module dispatch entry point, preserving CLI behavior without treating `index.zsh` as a second independently dispatched module.
- **Search dead snapshot helper removal (Issue #016).** Removed an unused snapshot-path helper and its unused path dependency from Search, and corrected the module documentation so it no longer claims unimplemented caching behavior.
- **Config path utility adoption (Issue #015).** Config now uses the shared XDG-aware resolver in `src/utils/path.zsh` instead of maintaining a duplicate path implementation; XDG and HOME fallback behavior remains unchanged.
- **Logger color utility adoption (Issue #014).** Logger now delegates ANSI sequences and shared `NO_COLOR` / `MDTK_NO_COLOR` policy to `src/utils/color.zsh`, removing duplicated color implementation while preserving its existing CLI-specific toggle.
- **Logger test environment isolation (Issue #013).** Logger specs now clear inherited color and mode environment variables before every example, so the default-color contract is tested deterministically even when the caller exports `NO_COLOR`.

### Added
- **Managed automatic update (Issue #029).** Added `mdtk update` for marker-validated XDG managed installations. It updates to the latest `main` by default or an optional `--ref` branch/tag by delegating to the same origin-verified installer workflow, then reruns setup and command-index construction; ordinary source checkouts are refused.
- **Installer managed ref selection (Issue #028).** Remote bootstrap installs now accept `MDTK_INSTALL_REF` for a branch or tag, record the selected ref, safely switch existing origin-verified managed checkouts, and migrate older managed installs without ref metadata; unsafe ref values are rejected before Git network operations.
- **Remote-friendly installer (Issue #022).** Added a top-level `install.sh` that works both from a local checkout and through `curl ... | zsh`. Remote mode atomically clones into the XDG data directory, marks the checkout for safe uninstall, verifies origin/branch before updates, refuses unmarked existing targets, and migrates older checkout hooks to the managed path.
- **One-command uninstall (Issue #021).** Added `mdtk uninstall` with confirmation, `--yes`, `--keep-config`, and `--dry-run`. It removes only links and shell-hook lines belonging to the running installation, validates destructive data paths, backs up `.zshrc`, and deletes a source tree only when it carries the expected managed-install marker at the XDG data location.
- **User-facing installer (Issue #011).** `scripts/install.sh` is the one-shot installer an end user runs (distinct from `install.zsh`, the developer bootstrap). It refuses on non-macOS/non-zsh, detects Homebrew (and prints the official install command if missing — does not auto-run the network pipe), symlinks `mdtk` onto the first writable on-PATH dir (`/usr/local/bin` or `~/.local/bin`), appends the `source scripts/mdtk.zsh` hook to `~/.zshrc` (idempotent, backed up first), runs an initial `mdtk index build`, and prints a friendly finish message. Tests in `tests/install/install_spec.sh` (isolated HOME/PATH per example).

## [0.1.0] - 2026-07-27

First usable release of MDTK. The toolkit now provides structured
logging, user configuration, a cache, a Homebrew backend, package
search, install recommendations, a command→formula index, and a
smart command-not-found handler wired into zsh.

### Added
- **command-not-found handler (Issue #010).** `src/cnf/cnf.zsh` looks up an unknown command in the index (#009) first, then falls back to the Homebrew backend, and prints a friendly Found/Run recommendation. CLI: `mdtk cnf <command>`. `scripts/mdtk.zsh` defines zsh's `command_not_found_handler` to call `mdtk cnf` (source it in `~/.zshrc`). Tests in `tests/cnf/cnf_spec.sh` (mock brew + prebuilt index).
- **Command index (Issue #009).** `src/cnf/index.zsh` builds a command→formula index from Homebrew (`brew list --formula` + each formula's aliases) and persists it to the cache dir as `command=formula` lines. API: `mdtk_index_build` / `mdtk_index_lookup <cmd>` + CLI `mdtk index {build|lookup|path|help}`. Sources `utils/path` (library) + homebrew backend (leaf). Tests mock `brew` (`tests/cnf/index_spec.sh`). Dispatcher now routes `index`.
- **Install recommendation (Issue #008).** `src/install/install.zsh` finds the Homebrew formula that provides a command and prints a friendly recommendation (Found/Run lines, per MASTER_PROMPT output style). Does NOT auto-install in v0.1. CLI: `mdtk install <command>`. Sources the homebrew backend (leaf). Tests mock `brew` (`tests/install/install_spec.sh`).
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
