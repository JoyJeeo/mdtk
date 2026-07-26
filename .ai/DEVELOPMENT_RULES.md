# Development Rules

> Iron rules for every contribution. Read before writing code. These apply on top of `.ai/MASTER_PROMPT.md` and `.ai/STYLE_GUIDE.md`.

## Scope of a change

- **Never modify multiple modules.** One change touches one module (plus its tests and docs). Cross-module work is split into separate tasks, one per module.
- **One commit = one feature.** A commit delivers exactly one feature (or one fix). Never bundle unrelated changes.

## Every feature must include

- **tests** — covering success, failure, edge cases, empty input, large input (see `.ai/TESTING.md`).
- **documentation** — the module header (Purpose / Input / Output / Examples) and any affected `docs/` page.
- **examples** — at least one runnable example in the function/file header.
- **CHANGELOG** — an entry in `CHANGELOG.md` describing what changed and why.

## Never

- Never skip tests.
- Never leave `TODO` in committed code.
- Never create dead code.
- Never create duplicated functions (extract to a `src/utils/` helper instead).
