# Current Task

## Target

Build the **Logger** module.

## Scope

Implement `src/modules/logger.zsh`, replacing the stub. Do not modify any other module.

## Requirements

### Levels (in priority order)

Support emitting at these levels:

- `INFO`
- `SUCCESS`
- `WARNING`
- `ERROR`
- `DEBUG`

### Modes

- **Colors** — colorized output when the terminal supports it.
- **No-color mode** — honor `NO_COLOR` (env var) and a `--no-color` flag / config; never emit ANSI codes when disabled.
- **Quiet mode** — suppress everything except `ERROR` (and `SUCCESS`? decide and document).
- **Debug mode** — emit `DEBUG` only when enabled (`--debug` flag / `MDTK_DEBUG=1` env / config).

### Interface (contract)

- Public entry point: `mdtk_logger_dispatch "$@"` (called by the dispatcher).
- Subcommands / flags should let a user invoke: `mdtk logger --info "message"`, `mdtk logger --error "boom"`, etc.
- Each level also exposes a callable function (e.g. `mdtk_logger_info`, `mdtk_logger_error`) so other modules — *after* logger lands — can log without going through the CLI. (Other modules will adopt it in their own tasks; do not wire them here.)

### Output format

- One line per message, prefixed with the level name (e.g. `[INFO] message`).
- Document the exact format and exit-code policy in the module header.

## Acceptance (DoD)

- Tests in `tests/` covering: each level, no-color, quiet, debug, empty input.
- Module header documents: Purpose / Input / Output / Examples (per `.ai/STYLE_GUIDE.md`).
- `make test` passes.
- No other module modified.
