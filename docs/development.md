# Development

> How to build, test, and contribute to MDTK.

If you are an AI coding agent, start at `AGENTS.md` at the repo root instead — it points you to the `.ai/` specs. This document is for humans and is the long-form companion.

## Prerequisites

- macOS (Apple Silicon or Intel)
- zsh (the default shell; you have 5.x)
- [conda](https://docs.conda.io) with an environment named `mdtk`
- `git`
- (optional) [Homebrew](https://brew.sh) — needed only to exercise the package backends, not to develop the core

## First-time setup

```sh
git clone <repo-url> mdtk
cd mdtk
conda activate mdtk
./scripts/dev-install.zsh
```

`scripts/dev-install.zsh` (the developer bootstrap) does three things:

1. Verifies you are in the `mdtk` conda env (it refuses to run otherwise, to keep tooling isolated).
2. Installs `shellspec` (the test framework) into the env, via `git clone` + `make install PREFIX=$CONDA_PREFIX`. It lives at `$CONDA_PREFIX/bin/shellspec`, so it is available only when the env is active. It also installs `shellcheck` (conda-forge) for the lint gate.
3. Symlinks `bin/mdtk` to `$CONDA_PREFIX/bin/mdtk`, so the `mdtk` command is on PATH while the env is active.

Its status labels are aligned and colored by level without icons; set
`NO_COLOR=1` for ANSI-free output.

It is idempotent — re-run it anytime after pulling changes that touch tooling.

> End users (who just want to use MDTK, not develop it) do **not** need conda. They use the top-level remote/local `install.sh`; see the README.

Verify:

```sh
mdtk version    # => mdtk 0.2.0
make test       # => all examples pass, 0 failures
```

## Repository layout

```
bin/mdtk              entry point (thin)
src/dispatcher.zsh    command dispatcher (infrastructure)
src/version.zsh       version constant
src/<module>/         one dir per module (logger/, config/, cache/, ...)
src/core/             project-level read-only constants
src/utils/            stateless shared helpers (color, path, shell)
src/backends/         package-manager wrappers (homebrew, pip, ...)
tests/                shellspec tests
scripts/              standalone dev helper scripts
.ai/                  project specifications (read first)
docs/                 human-facing docs (this folder)
AGENTS.md             instructions for AI coding agents
scripts/dev-install.zsh  developer bootstrap (test tooling)
Makefile              test / install / smoke / help targets
```

## The two doc trees

- **`.ai/`** — the specification. Authoritative, machine-precise, read by both humans and AI agents. Start here.
- **`docs/`** — the narrative for humans (vision, FAQ, architecture, this file).

When they conflict, `.ai/` wins.

## Linting and parse-checking

```sh
conda activate mdtk
make lint    # zsh -n (hard parse gate) + shellcheck (advisory)
make syntax  # just the parse gate
```

`zsh -n` is the real "does it compile?" gate for a zsh project. ShellCheck
does not support zsh natively, so `make lint` runs it in sh mode and flags
zsh-only constructs (`local`, `${x:h}`, `source`) — those are expected and fine;
treat real, bash/sh-compatible issues as blockers. This matches the DoD in
`.ai/DOD.md`.

## Running tests

```sh
conda activate mdtk
make test
```

This runs `shellspec`, which discovers `tests/**/*_spec.sh` and runs them under zsh (pinned in `.shellspec`).

- Run a single spec file: `make testone FILE=tests/bin/mdtk_spec.sh` (or `shellspec tests/bin/mdtk_spec.sh`)
- Run with focus on a failing example: `shellspec --focus` (see shellspec docs)

Every module requires tests; every bug fix requires a regression test. Coverage target is >90% (`.ai/TESTING.md`).

## Smoke-testing the CLI

```sh
make smoke
```

Runs a handful of `mdtk` commands against the current skeleton and prints their output. Useful after restructuring the dispatcher or entry point.

## How to add a feature

Work flows as **issues** (`.ai/ISSUE_PROCESS.md`): one issue = one module =
one feature. The top open issue in `.ai/TASK.md` is the current task. The
workflow is deliberately small:

1. **Read the specs.** Every file under `.ai/`, especially `.ai/TASK.md` (the current issue).
2. **Pick up the current issue.** The top open issue in `.ai/TASK.md`. Do not implement outside it.
3. **Implement that one module** in `src/<name>/<name>.zsh`, replacing its stub. Follow `.ai/STYLE_GUIDE.md`.
4. **Write tests** for it in `tests/`. Include success, failure, edge cases, empty input, large input (`.ai/TESTING.md`).
5. **Update docs.** If behavior changes, update the relevant `docs/` page and the module's own header comment.
6. **Add a CHANGELOG entry** under `[Unreleased]` in `CHANGELOG.md` (what changed and why).
7. **Definition of Done.** Verify every box in `.ai/DOD.md` is checked — `make lint` (parse + advisory shellcheck) and `make test` green. Do not commit otherwise.
8. **Review.** Run the senior-reviewer prompt (`.ai/REVIEW_PROMPT.md`) against the whole diff. The reviewer does **not** write code — only finds issues across architecture / performance / security / shell compatibility / maintainability / documentation / testing. Fix every BLOCKER, re-review, then merge. Never merge unreviewed.
9. **Commit one feature.** One commit = one feature (per `.ai/DEVELOPMENT_RULES.md`). Do not bundle unrelated changes.
10. **Close the issue** in `.ai/TASK.md` (move to "Closed"), then open the next from the queue. Do not start the next issue unless asked.

Do not modify unrelated modules. Do not leave TODOs. Do not create dead code or duplicated functions. (These are iron rules — see `.ai/DEVELOPMENT_RULES.md`.)

## Coding style (quick reference)

Full rules: `.ai/STYLE_GUIDE.md`.

- zsh; `snake_case` functions; `lowercase` variables; `UPPER_CASE` constants.
- 4-space indent; prefer double quotes.
- `local` inside every function; no globals.
- Every file: header with Purpose / Author / Date.
- Every function: Description / Parameters / Return / Example.

## Working with the conda env

All commands assume `conda activate mdtk` has been run. If `mdtk` or `shellspec` is "command not found", you forgot to activate the env, or `scripts/dev-install.zsh` has not been run.

```sh
source /opt/homebrew/anaconda3/etc/profile.d/conda.sh   # if conda is not on PATH
conda activate mdtk
```

## Commit policy

- One commit = one feature (plus its tests and docs).
- Keep commits small and reviewable.
- Do not commit generated test artifacts (`report/`, `coverage/`, `.shellspec-quick.log`, `.shellspec-local`) — they are gitignored.
- End commit messages with:

  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

  when the commit was co-authored with an AI agent.

## Reviewing work

Per the project's review philosophy, do not merge a module straight after writing it. Switch to the **senior-reviewer role** (a different role than the implementer) and review the whole diff before merging. The full prompt lives in `.ai/REVIEW_PROMPT.md` — it covers architecture, performance, security, shell compatibility, maintainability, documentation, and testing. The reviewer does **not** write code; it lists findings, marks hard ones as BLOCKER, and the implementer fixes those before re-review and merge. Never merge unreviewed.

## Where to get help

- `.ai/` — the specs.
- `docs/faq.md` — common questions.
- `docs/architecture.md` — how the pieces fit.
- `AGENTS.md` — agent-specific instructions.
