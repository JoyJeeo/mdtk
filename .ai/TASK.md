# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.
> v0.1 order per docs/read2.md.

## Current issue

### #009 Command Index — **open**

Implement `src/cnf/index.zsh`: a command->formula index, persisted
to the cache dir via utils/path. Built from the Homebrew backend's
installed formulae (`brew list --formula`) + their aliases.

- API: `mdtk_index_build` (scan brew, write index file),
  `mdtk_index_lookup <command>` (print formula or nothing),
  `mdtk_index_dispatch` (CLI: `mdtk index build|lookup|path|help`).
- Storage: a `command_index` cache file; lines of `command=formula`.
- Tests: mock brew; covers build, lookup hit/miss, empty, rebuild.
- DoD: header docs, `make test` green, no other module touched.

---

## Queue (next, not started)

- #010 command_not_found_handler — `src/cnf/cnf.zsh` + `scripts/mdtk.zsh` shell hook.

---

## Closed

### #008 Install Recommendation — **closed**

Implemented the Install module.

- mdtk install <cmd>: finds formula via homebrew provides; prints
  Found/Run recommendation. Does NOT auto-install in v0.1.
- Sources homebrew backend (leaf). Tests mock brew; 5 examples green.
- DoD met; reviewed; merged.

### #007 Search Engine — **closed**

Implemented the Search module.

- Queries the Homebrew backend; prints formulae one/line.
- CLI: mdtk search <query>. Sources utils/path + homebrew backend.
- Tests mock brew; 5 examples, all green.
- DoD met; reviewed; merged.

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
