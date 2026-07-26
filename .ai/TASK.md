# Task Backlog

> The issue queue. Work is tracked as issues (`.ai/ISSUE_PROCESS.md`),
> not as a single rolling task. One issue is current at a time.

## Current issue

### #002 Config — **open**

Implement the Config module.

#### Target

`src/config/config.zsh` (replace the stub). Do not modify any other module.

#### Requirements (to be detailed when this issue is worked)

- Read and write user configuration (XDG-aware location).
- Expose a small, documented API for other modules to get/set values.
- Honor a no-color / quiet / debug default sourced from config (where it
  overlaps with Logger modes).
- Tests: success, failure, edge cases, empty input, large input.
- Module header: Purpose / Input / Output / Examples (`.ai/STYLE_GUIDE.md`).
- `make test` passes. No other module modified.

> Filled out fully when issue #002 is picked up (the implementer expands
> the acceptance checklist then).

---

## Queue (next, not started)

> Open an issue from this queue only after the current one is closed.
> Sourced from `.ai/ROADMAP.md` v0.1.

- #003 Cache
- #004 Search

---

## Closed

### #001 Logger — **closed**

Implemented the Logger module.

- Levels: INFO / SUCCESS / WARNING / ERROR / DEBUG.
- Color by default; `NO_COLOR` env / `--no-color` disable.
- `--quiet` (ERROR only); `--debug` / `MDTK_DEBUG=1` for DEBUG.
- Output format: `[LEVEL] message`.
- Per-level functions `mdtk_logger_<level>` exposed for other modules.
- Tests: `tests/logger/logger_spec.sh` (18 examples, all green).
- DoD met; reviewed; merged.
