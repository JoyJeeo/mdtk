# Coding Style

## Language

Shell (zsh). Code targets zsh 5.x (the macOS default); do not rely on bashisms.

## Naming

- **Functions:** `snake_case`
- **Variables:** `lowercase`
- **Constants:** `UPPER_CASE` and declared with `typeset -r`

## Scope

- Always use `local` inside functions.
- **No mutable global variables.** The only exception is a module-level constant declared `typeset -r` at the top of a file (e.g. `MDTK_VERSION`).
- Module-private helpers (not part of the dispatch contract) are prefixed with an underscore: `_mdtk_<name>_*`. They are not meant to be called from outside the file.

## Formatting

- Indentation: 4 spaces (no tabs).
- Quotes: prefer double quotes.
- No trailing whitespace.

## File header (every file begins with)

- Purpose
- Author
- Date

## Function header (every function documents)

- Description
- Parameters
- Return
- Example

## Strict mode

- Prefer `set -eu` and `set -o pipefail` in scripts with a `main`/top-level flow (e.g. `install.sh`, `scripts/install.sh`, `scripts/dev-install.zsh`).
- Do **not** enable `set -u` (nounset) globally in sourced library files or in `tests/spec_helper.sh` — it interacts poorly with optional/empty parameters and with the shellspec runtime.

## Quality

- No duplicated logic (extract to a `src/utils/` helper).
- No dead code. No `TODO` left in committed code.
