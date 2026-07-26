# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.
> v0.1 order per docs/read2.md.

## Current issue

### #003 Utils — **open**

Implement the stateless shared helpers: `src/utils/path.zsh`,
`src/utils/color.zsh`, `src/utils/shell.zsh`. These are a library,
not a module (no dispatch function). Other modules source them.

- path: `mdtk_utils_path_config`, `mdtk_utils_path_cache`, `mdtk_utils_path_root`.
- color: `mdtk_utils_color_for <name>`, `mdtk_utils_color_enabled`, reset.
- shell: `mdtk_utils_shell_zsh_version`, optional-env reader.
- Tests: per helper, success/failure/edge/empty.
- DoD: header docs, `make test` green, no other module touched.

---

## Queue (next, not started)

- #004 Cache — `src/cache/cache.zsh`; build/get/clean; uses utils/path.
- #005 Command Dispatcher — enhance `src/dispatcher.zsh`: add `cnf` route, refresh help text.
- #006 Homebrew Backend — `src/backends/homebrew.zsh`; search/provides/install; mock brew in tests.
- #007 Search Engine — `src/search/search.zsh`; query backends via cache.
- #008 Install Recommendation — `src/install/install.zsh`; recommend formula for a command.
- #009 Command Index — `src/cnf/index.zsh`; map command->formula, persisted via cache.
- #010 command_not_found_handler — `src/cnf/cnf.zsh` + `scripts/mdtk.zsh` shell hook.

---

## Closed

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
