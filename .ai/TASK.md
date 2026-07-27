# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.
> v0.1 order per docs/read2.md.

## Current issue

(none — all v0.1 issues are closed; release v0.1.0 follows.)

---

## Queue (next, not started)

(v0.1 complete. Next milestone: v0.2 — Doctor, Plugin, etc.)

---

## Closed

### #010 command_not_found_handler — **closed**

Implemented the command-not-found handler module.

- src/cnf/cnf.zsh: index lookup first, homebrew backend fallback,
  friendly Found/Run recommendation.
- scripts/mdtk.zsh: defines command_not_found_handler to call mdtk cnf.
- CLI: mdtk cnf <cmd>. Tests mock brew + prebuilt index; 6 examples green.
- DoD met; reviewed; merged. v0.1.0 ready to release.

### #009 Command Index — **closed**

Implemented the Command Index module.

- Builds command=formula index from brew list + aliases; persisted to
  cache dir. lookup by command name.
- CLI: mdtk index {build|lookup|path|help}. Sources utils/path +
  homebrew backend. Dispatcher routes `index`.
- Tests mock brew; 8 examples, all green.
- DoD met; reviewed; merged.

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
