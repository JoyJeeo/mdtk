# Architecture

> How MDTK is put together. The human-facing companion to `.ai/ARCHITECTURE.md`.

This document explains the *shape* of the codebase and the rules that keep it from rotting. If `.ai/ARCHITECTURE.md` is the spec, this is the tour.

## The big picture

MDTK is a single command (`mdtk`) with subcommands. The flow is strictly one-directional:

```
bin/mdtk            (entry point — thin, no logic)
      │
      ▼
src/dispatcher.zsh  (the only thing that knows about all modules)
      │
      ▼
src/modules/*.zsh   (one file per feature: logger, config, cache, …)
      │
      ▼
backends            (Homebrew, pip, cargo, conda, npm — future)
```

There is exactly one rule that the whole architecture exists to enforce:

> **Modules never call each other directly. Everything goes through the dispatcher.**

That rule is what keeps the project from becoming a tangled web as it grows.

## The layers

### Entry point — `bin/mdtk`

A deliberately boring script. It locates the project root, sources the dispatcher, and forwards `"$@"`. No flags parsing, no business logic, no decisions. If you are tempted to add logic here, you are in the wrong layer.

### Dispatcher — `src/dispatcher.zsh`

The dispatcher is the **only** piece of code that knows the names of every module. Its job is narrow:

- Take the first argument (`$1`) as the subcommand.
- Handle a couple of built-ins itself (`version`, `help`).
- For everything else, route to the matching module's `mdtk_<name>_dispatch` function.
- On an unknown command, give a friendly message and a pointer to `mdtk help`.

Because modules are loaded on demand (`source` at call time), shell startup stays fast — you only pay for the module you actually invoke. This is the architecture's answer to the performance goal in `.ai/MASTER_PROMPT.md`.

### Modules — `src/modules/*.zsh`

Each module owns one responsibility:

| Module   | Responsibility                                    |
| -------- | ------------------------------------------------- |
| logger   | Structured logging (INFO/SUCCESS/WARNING/ERROR/DEBUG). |
| config   | Read and write user configuration.                |
| cache    | Store and retrieve cached results (e.g. command index). |
| search   | Search packages across backends.                  |
| install  | Recommend a package and run the install.           |
| doctor   | Diagnose the developer environment.               |
| plugin   | Discover and load plugins.                        |

Every module exposes exactly one entry point: `mdtk_<name>_dispatch "$@"`. That contract is the whole interface between the dispatcher and a module. Modules do **not** source each other; if module A needs something module B does, the user runs `mdtk B …`, or a future backend layer provides shared utilities behind a documented API.

### Backends (future)

Modules like `search` and `install` will talk to package managers — Homebrew first, then pip, cargo, conda, npm (see `.ai/ROADMAP.md`). Backends are a separate layer *below* modules. A module calls a backend; a backend never calls a module.

## Why this shape

| Force                              | How the architecture answers it                          |
| ---------------------------------- | -------------------------------------------------------- |
| "Modules keep calling each other"  | Forbidden. Routes go through the dispatcher only.        |
| "Startup got slow"                  | Modules are sourced on demand, not at shell init.       |
| "I don't know what a file does"     | One responsibility per file, documented header, one entry point per module. |
| "Changing X broke Y"                | No shared mutable globals; modules are independent.      |
| "Newcomers can't extend it"         | Add a module = add one file + one `case` branch + one dispatch function. |

## Coding conventions

The full style rules live in `.ai/STYLE_GUIDE.md`. The highlights:

- **Language:** zsh.
- **Naming:** functions `snake_case`, variables `lowercase`, constants `UPPER_CASE`.
- **Indentation:** 4 spaces. **Quotes:** prefer double quotes.
- **Locality:** `local` inside every function; no global variables.
- **Documentation:** every file begins with Purpose/Author/Date; every function documents Description/Parameters/Return/Example.

## Testing

Tests live in `spec/` and run with `shellspec` under zsh. Every module requires tests; every bug fix requires a regression test (see `.ai/TESTING.md`). The current `spec/bin/mdtk_spec.sh` is a smoke suite for the skeleton — it will be joined by per-module specs as features land.

## Where the spec lives

The machine-precise, AI-facing rules are in `.ai/`:

- `.ai/ARCHITECTURE.md` — the canonical architecture rules.
- `.ai/MASTER_PROMPT.md` — core principles.
- `.ai/STYLE_GUIDE.md` — coding style.

This document is the narrative. When they disagree, the `.ai/` version wins.
