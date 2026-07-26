# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.

## Current issue

### #001 Logger — **open**

Implement the Logger module.

#### Target

`src/logger/logger.zsh` (replace the stub). Do not modify any other module.

#### Levels (priority order)

- `INFO`
- `SUCCESS`
- `WARNING`
- `ERROR`
- `DEBUG`

#### Modes

- Colors — colorized output when supported.
- No-color — honor `NO_COLOR` env / `--no-color` flag; never emit ANSI when disabled.
- Quiet — suppress everything except `ERROR`.
- Debug — emit `DEBUG` only when enabled (`--debug` flag / `MDTK_DEBUG=1` env / config).

#### Interface (contract)

- Public entry point: `mdtk_logger_dispatch "$@"`.
- CLI: `mdtk logger --info "msg"`, `mdtk logger --error "boom"`, etc.
- Per-level callable functions: `mdtk_logger_info`, `mdtk_logger_error`, …
  (other modules adopt them in their own issues; do not wire them here).

#### Output format

- One line per message, prefixed with the level name (e.g. `[INFO] message`).
- Document the exact format and exit-code policy in the module header.

#### Acceptance (DoD)

- Tests: each level, no-color, quiet, debug, empty input.
- Module header: Purpose / Input / Output / Examples (`.ai/STYLE_GUIDE.md`).
- `make test` passes.
- No other module modified.

---

## Queue (next, not started)

> Open an issue from this queue only after the current one is closed.
> Sourced from `.ai/ROADMAP.md` v0.1.

- #002 Config
- #003 Cache
- #004 Search

---

## Closed

(none yet)
