# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.
> v0.1 order per docs/read2.md.

## Current issue

### #005 Command Dispatcher — **open**

Enhance `src/dispatcher.zsh`: add a `cnf` route (for the
command_not_found_handler module, #010) and refresh the help text
(now that modules are landing). Do NOT break the existing
version/help/unknown behavior or the module routing contract.

- Add `cnf` to the routed commands -> `src/cnf/cnf.zsh` (file lands in #010; route now so #010 need not touch dispatcher).
- Refresh `mdtk_dispatch_help` text to reflect real (not "not implemented") status where modules have landed.
- Tests: extend `tests/bin/mdtk_spec.sh` to cover `help` reflecting landed modules; `cnf` route presence.
- DoD: header docs, `make test` green, no other module's *behavior* changed.

---

## Queue (next, not started)

- #006 Homebrew Backend — `src/backends/homebrew.zsh`; search/provides/install; mock brew in tests.
- #007 Search Engine — `src/search/search.zsh`; query backends via cache.
- #008 Install Recommendation — `src/install/install.zsh`; recommend formula for a command.
- #009 Command Index — `src/cnf/index.zsh`; map command->formula, persisted via cache.
- #010 command_not_found_handler — `src/cnf/cnf.zsh` + `scripts/mdtk.zsh` shell hook.

---

## Closed

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
