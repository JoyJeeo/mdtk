# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.
> v0.1 order per docs/read2.md.

## Current issue

### #007 Search Engine — **open**

Implement `src/search/search.zsh`: the search module. Queries the
Homebrew backend, caches results via the cache module (sourced as a
library — wait, search is a module and must NOT source cache). Per
ARCHITECTURE rule 1, modules do not source each other. So search
calls the backend directly (a backend is a leaf, allowed) and writes
its own cache via utils (or a private cache helper).

- API: `mdtk_search_dispatch "$@"` (CLI: `mdtk search <query>`).
- Calls `mdtk_backend_homebrew_search`; prints results one/line.
- Caches search snapshots via the cache module's API through the
  dispatcher? No — call `mdtk_cache_*` would be cross-module. Use a
  private on-disk cache under utils cache dir instead.
- Tests: mock brew; covers query, empty, no results, missing brew.
- DoD: header docs, `make test` green, no other module touched.

---

## Queue (next, not started)

- #008 Install Recommendation — `src/install/install.zsh`; recommend formula for a command.
- #009 Command Index — `src/cnf/index.zsh`; map command->formula, persisted via cache.
- #010 command_not_found_handler — `src/cnf/cnf.zsh` + `scripts/mdtk.zsh` shell hook.

---

## Closed

### #006 Homebrew Backend — **closed**

Implemented the Homebrew backend.

- available/search/provides/install; leaf (no module calls).
- provides: same-name formula first, then alias scan via brew info JSON.
- Tests mock brew (function override); 10 examples, all green.
- DoD met; reviewed; merged.

### #005 Command Dispatcher — **closed**

Enhanced the dispatcher.

- Added `cnf` route -> src/cnf/cnf.zsh (stub now, real in #010).
- Refreshed help text (landed modules + cnf).
- No behavior change to version/help/unknown/module routing.
- Tests: extended tests/bin/mdtk_spec.sh (help has cnf; cnf route).
- DoD met; reviewed; merged.

### #004 Cache — **closed**

Implemented the Cache module.

- XDG-aware cache dir; one file per name; names restricted to [a-z0-9_]+.
- API: get/set/clean; CLI: mdtk cache {get|set|clean|list|path|help}.
- Sources utils/path (library, allowed).
- Tests: `tests/cache/cache_spec.sh` (14 examples, all green).
- DoD met; reviewed; merged.

### #003 Utils — **closed**

Implemented the Utils library (stateless shared helpers).

- path: root/config/cache_dir/cache_file (XDG-aware).
- color: enabled/for/reset (honors NO_COLOR + MDTK_NO_COLOR).
- shell: zsh_version/has_option/env_get (set-u-safe).
- Tests: `tests/utils/utils_spec.sh` (14 examples, all green).
- DoD met; reviewed; merged.

### #002 Config — **closed**

Implemented the Config module.

- XDG-aware config file at `$XDG_CONFIG_HOME/mdtk/config` (or `$HOME/.config/mdtk/config`).
- API: `mdtk_config_get` / `mdtk_config_set`; CLI `mdtk config {get|set|list|path|help}`.
- Missing key returns 1; set overwrites or appends; isolated XDG in tests.
- Tests: `tests/config/config_spec.sh` (11 examples, all green).
- DoD met; reviewed; merged.

### #001 Logger — **closed**

Implemented the Logger module.

- Levels: INFO / SUCCESS / WARNING / ERROR / DEBUG.
- Color by default; `NO_COLOR` env / `--no-color` disable.
- `--quiet` (ERROR only); `--debug` / `MDTK_DEBUG=1` for DEBUG.
- Output format: `[LEVEL] message`.
- Per-level functions `mdtk_logger_<level>` exposed for other modules.
- Tests: `tests/logger/logger_spec.sh` (18 examples, all green).
- DoD met; reviewed; merged.
