# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.
> v0.1 order per docs/read2.md.

## Current issue

### #004 Cache — **open**

Implement the Cache module: `src/cache/cache.zsh`. Stores and
retrieves cached results (command index, brew search snapshots) at
an XDG-aware cache dir. Sources utils/path (library, allowed).

- API: `mdtk_cache_get <name>`, `mdtk_cache_set <name> <value>`,
  `mdtk_cache_clean`, `mdtk_cache_dispatch` (CLI: build/get/clean/path/help).
- Storage: one file per cache name under the cache dir.
- Tests: get missing, set+get, overwrite, clean, large input.
- DoD: header docs, `make test` green, no other module touched.

---

## Queue (next, not started)

- #005 Command Dispatcher — enhance `src/dispatcher.zsh`: add `cnf` route, refresh help text.
- #006 Homebrew Backend — `src/backends/homebrew.zsh`; search/provides/install; mock brew in tests.
- #007 Search Engine — `src/search/search.zsh`; query backends via cache.
- #008 Install Recommendation — `src/install/install.zsh`; recommend formula for a command.
- #009 Command Index — `src/cnf/index.zsh`; map command->formula, persisted via cache.
- #010 command_not_found_handler — `src/cnf/cnf.zsh` + `scripts/mdtk.zsh` shell hook.

---

## Closed

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
