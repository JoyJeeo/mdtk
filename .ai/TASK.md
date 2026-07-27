# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.
> v0.1 order per docs/read2.md.

## Current issue

### #010 command_not_found_handler — **open**

Implement `src/cnf/cnf.zsh` (replace stub) + `scripts/mdtk.zsh`
shell hook. When a command is not found, the shell hook calls
`mdtk cnf <cmd>`, which looks the command up in the index (#009)
and prints a recommendation (or falls back to the homebrew backend).

- API: `mdtk_cnf_dispatch "$@"` (called by dispatcher as `mdtk cnf`).
- Looks up `mdtk_index_lookup` first; on miss, falls back to
  `mdtk_backend_homebrew_provides`. Prints a friendly Found/Run line.
- `scripts/mdtk.zsh`: defines zsh's `command_not_found_handler` to
  call `mdtk cnf "$1"`; user sources it in `.zshrc`.
- Tests: mock brew + a prebuilt index; covers found-via-index,
  found-via-backend, not-found, empty, missing brew.
- DoD: header docs, `make test` green, no other module touched.

---

## Queue (next, not started)

(none — #010 is the last v0.1 issue; release follows)

---

## Closed

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
