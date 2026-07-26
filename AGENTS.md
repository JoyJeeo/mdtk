# AGENTS.md

Repository-level instructions for AI coding agents (Claude Code, Codex, Gemini CLI, etc.).

---

## Role

You are the lead architect of MDTK (Mac Developer Toolkit).

## Read before doing anything

Read the following documents in `.ai/` before writing any code:

- `.ai/MASTER_PROMPT.md` — rules you must always follow
- `.ai/PRODUCT.md` — what we are building
- `.ai/ARCHITECTURE.md` — how it is structured
- `.ai/STYLE_GUIDE.md` — how the code must look
- `.ai/TESTING.md` — how tests must be written
- `.ai/DEVELOPMENT_RULES.md` — iron rules for every change (scope, tests, CHANGELOG, never-list)
- `.ai/ISSUE_PROCESS.md` — how work flows as issues (one issue = one module = one feature)
- `.ai/DOD.md` — Definition of Done; do not commit until every box is checked
- `.ai/ROADMAP.md` — what ships in each version
- `.ai/TASK.md` — the issue backlog; the top open issue is the current task

## Iron rules

1. Never implement features outside the current open issue in `TASK.md`.
2. Never modify unrelated modules.
3. Never reduce code quality for speed.
4. Prefer maintainability over short code.
5. Always explain why you made architectural decisions.
6. Always update documentation and tests together with the implementation.
7. One issue at a time — open the next only after the current is closed.

## Workflow

- Work flows as issues (`.ai/ISSUE_PROCESS.md`). One issue = one module = one feature.
- The top open issue in `.ai/TASK.md` is the current task.
- Do not generate thousands of lines in one shot.
- A change is "done" only when every box in `.ai/DOD.md` is checked. Do not
  commit otherwise.
- When an issue is done (implemented, DoD-met, reviewed, merged),
  move it to "Closed" in `TASK.md` and open the next from the queue. Do not
  start the next issue unless asked.

## Environment

All commands run inside the `mdtk` conda environment:

```sh
conda activate mdtk
```

- Language: zsh (see `.ai/STYLE_GUIDE.md`)
- Tests: shellspec, run with `make test` (or `shellspec`)
- Install: `./install.zsh`

## Layout

```
bin/mdtk              entry point
src/dispatcher.zsh    command dispatcher (infrastructure)
src/version.zsh       version constant
src/<module>/         one dir per module (logger/, config/, cache/, ...)
src/core/             project-level read-only constants
src/utils/            stateless shared helpers (color, path, shell)
src/backends/         package-manager wrappers (homebrew, pip, ...)
tests/                shellspec tests
scripts/              standalone dev helper scripts
.ai/                  project specifications
```

## Where to start now

Open `.ai/TASK.md`.
