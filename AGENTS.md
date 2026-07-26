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
- `.ai/ROADMAP.md` — what ships in each version
- `.ai/TASK.md` — the single task you are allowed to work on right now

## Iron rules

1. Never implement features outside `TASK.md`.
2. Never modify unrelated modules.
3. Never reduce code quality for speed.
4. Prefer maintainability over short code.
5. Always explain why you made architectural decisions.
6. Always update documentation and tests together with the implementation.

## Workflow

- One task at a time. Each task = one feature + its tests + its docs.
- Do not generate thousands of lines in one shot.
- When a task is done, update `TASK.md` to point at the next one (do not start it unless asked).

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
src/modules/*.zsh     one file per module (Logger, Config, Cache, ...)
spec/                 shellspec tests
.ai/                  project specifications
```

## Where to start now

Open `.ai/TASK.md`.
