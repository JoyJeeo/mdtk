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
./install.zsh
```

`install.zsh` does three things:

1. Verifies you are in the `mdtk` conda env (it refuses to run otherwise, to keep tooling isolated).
2. Installs `shellspec` (the test framework) into the env, via `git clone` + `make install PREFIX=$CONDA_PREFIX`. It lives at `$CONDA_PREFIX/bin/shellspec`, so it is available only when the env is active.
3. Symlinks `bin/mdtk` to `$CONDA_PREFIX/bin/mdtk`, so the `mdtk` command is on PATH while the env is active.

It is idempotent — re-run it anytime after pulling changes that touch tooling.

Verify:

```sh
mdtk version    # => mdtk 0.0.1
make test       # => 5 examples, 0 failures
```

## Repository layout

```
bin/mdtk              entry point (thin)
src/dispatcher.zsh    command dispatcher (infrastructure)
src/version.zsh       version constant
src/modules/*.zsh     one stub per module
spec/                 shellspec tests
.ai/                  project specifications (read first)
docs/                 human-facing docs (this folder)
AGENTS.md             instructions for AI coding agents
install.zsh           environment bootstrap
Makefile              test / install / smoke / help targets
```

## The two doc trees

- **`.ai/`** — the specification. Authoritative, machine-precise, read by both humans and AI agents. Start here.
- **`docs/`** — the narrative for humans (vision, FAQ, architecture, this file).

When they conflict, `.ai/` wins.

## Running tests

```sh
conda activate mdtk
make test
```

This runs `shellspec`, which discovers `spec/**/*_spec.sh` and runs them under zsh (pinned in `.shellspec`).

- Run a single spec file: `shellspec spec/bin/mdtk_spec.sh`
- Run with focus on a failing example: `shellspec --focus` (see shellspec docs)

Every module requires tests; every bug fix requires a regression test. Coverage target is >90% (`.ai/TESTING.md`).

## Smoke-testing the CLI

```sh
make smoke
```

Runs a handful of `mdtk` commands against the current skeleton and prints their output. Useful after restructuring the dispatcher or entry point.

## How to add a feature

MDTK is built one task at a time. The workflow is deliberately small:

1. **Read the specs.** Every file under `.ai/`, especially `.ai/TASK.md`.
2. **Pick up one task.** Whatever `.ai/TASK.md` names. Do not implement outside it.
3. **Implement that one module** in `src/modules/<name>.zsh`, replacing its stub. Follow `.ai/STYLE_GUIDE.md`.
4. **Write tests** for it in `spec/`. Include success, failure, edge cases, empty input, large input (`.ai/TESTING.md`).
5. **Update docs.** If behavior changes, update the relevant `docs/` page and the module's own header comment.
6. **Run the full suite:** `make test`.
7. **Commit one feature.** One commit = one feature. Do not bundle unrelated changes.
8. **Update `.ai/TASK.md`** to point at the next module. Do not start the next task unless asked.

Do not modify unrelated modules. Do not leave TODOs. Do not create dead code or duplicated functions.

## Coding style (quick reference)

Full rules: `.ai/STYLE_GUIDE.md`.

- zsh; `snake_case` functions; `lowercase` variables; `UPPER_CASE` constants.
- 4-space indent; prefer double quotes.
- `local` inside every function; no globals.
- Every file: header with Purpose / Author / Date.
- Every function: Description / Parameters / Return / Example.

## Working with the conda env

All commands assume `conda activate mdtk` has been run. If `mdtk` or `shellspec` is "command not found", you forgot to activate the env, or `install.zsh` has not been run.

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

Per the project's review philosophy, do not merge a module straight after writing it. First review the whole change as a senior reviewer would: architecture, performance, security, shell compatibility, maintainability, documentation, testing. Find issues, do not write code during review. (See `docs/read.md` for the full review prompt.)

## Where to get help

- `.ai/` — the specs.
- `docs/faq.md` — common questions.
- `docs/architecture.md` — how the pieces fit.
- `AGENTS.md` — agent-specific instructions.
