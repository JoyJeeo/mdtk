# Definition of Done

> A module (issue) is only "done" when **every** box below is checked.
> If any box is unchecked, the change must not be committed. An issue is
> not closed until the change is done and merged.

## Checklist

- [ ] **Compiles / parses.** The script parses cleanly under zsh (`zsh -n` passes on every touched file; `make syntax` green).
- [ ] **ShellCheck passes (advisory).** `make lint` runs; shellcheck does not support zsh natively, so it runs in sh mode and flags zsh-isms (expected). Treat real issues as blockers; zsh-only constructs (`local`, `${x:h}`, `source`) are fine. The hard gate is `zsh -n` above.
- [ ] **Tests pass.** `make test` is green, and the new tests cover success, failure, edge cases, empty input, and large input (`.ai/TESTING.md`).
- [ ] **README updated.** If user-visible behavior changed, `README.md` reflects it.
- [ ] **Examples updated.** The module/function header includes at least one runnable example (`.ai/STYLE_GUIDE.md`).
- [ ] **CHANGELOG updated.** An `[Unreleased]` entry in `CHANGELOG.md` describes what changed and why (`.ai/DEVELOPMENT_RULES.md`).
- [ ] **No TODO.** No `TODO` / `FIXME` / `XXX` left in committed code.
- [ ] **No duplicated code.** No duplicated logic; shared bits live in `src/utils/` (`.ai/ARCHITECTURE.md`).
- [ ] **API documented.** Every public function documents Description / Parameters / Return / Example (`.ai/STYLE_GUIDE.md`).
- [ ] **Scope respected.** No module other than the issue's target was modified (`.ai/DEVELOPMENT_RULES.md`).

## Gate

> **禁止提交 / Do not commit** until every box is checked. `zsh -n`
> (parse) and `make test` are hard gates; shellcheck is advisory. An issue is
> closed only after the done change is reviewed and merged
> (`.ai/ISSUE_PROCESS.md`).

## How to check

```sh
conda activate mdtk
make lint   # zsh -n (hard) + shellcheck (advisory)
make test   # shellspec suite
```
