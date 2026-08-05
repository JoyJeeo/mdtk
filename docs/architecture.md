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
src/<module>/        (one directory per feature: logger/, config/, cache/, …)
      │
      ▼
src/backends/        (Homebrew, pip, cargo, conda, npm)
```

`src/utils/` and `src/core/` sit alongside: stateless shared helpers and
project-wide constants, neither a module and neither calling back upward.

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

### Modules — `src/<module>/<module>.zsh`

Each module owns one responsibility:

| Module   | Responsibility                                    |
| -------- | ------------------------------------------------- |
| logger   | Structured logging (INFO/SUCCESS/WARNING/ERROR/DEBUG). |
| config   | Read and write user configuration.                |
| cache    | Store and retrieve cached results (e.g. command index). |
| search   | Search packages across backends.                  |
| install  | Recommend a package installation command.          |
| uninstall | Remove MDTK-managed links, hooks, and user data.   |
| doctor   | Read-only diagnosis of the local MDTK environment. |
| plugin   | Discover and load plugins.                        |

Every module exposes exactly one entry point: `mdtk_<name>_dispatch "$@"`. That contract is the whole interface between the dispatcher and a module. A complex module may split private components into the same directory, but those files have no public dispatch entry point and are never routed directly. Modules do **not** source each other; if module A needs something module B does, the user runs `mdtk B …`, or a backend/shared utility provides the lower-level capability.

### Backends

Modules like `search`, `install`, and `cnf` talk to package managers through backends. Homebrew, pip, cargo, conda, and npm are implemented; docker and sdkman are post-v1.0 possibilities (see `.ai/ROADMAP.md`). Homebrew remains the default, while Search and Install accept an explicit backend. CNF index storage isolates sorted `command=package` files below the XDG cache and bounds all five files to 80 MiB total; lookup can select one backend or read every local file in fixed product order without calling a backend or the network. The legacy Homebrew index remains the default compatibility path during the v1.1 transition. Backends are a separate layer *below* modules. A module calls a backend; a backend never calls a module. The canonical backend list lives in `.ai/PRODUCT.md`; keep the product, architecture, and roadmap lists in sync.

The pip, npm, Cargo, and conda index sources are small maintained files in
`catalogs/`. Their CNF compiler validates every record, resolves collisions by
rank, byte-sorts the result, enforces the backend capacity, and atomically
replaces the destination. This compilation path is deliberately offline;
Homebrew continues to use its complete executable metadata instead.

`mdtk index build` and `mdtk index refresh` run the same explicit refresh
orchestrator. It processes selected backends in product order, continues after
a backend failure, and atomically records rebuilt/failed/not-selected states in
the manifest. A failed backend retains its previous isolated index. The legacy
Homebrew cache file is updated alongside the isolated Homebrew index for CLI
and shell-hook compatibility.

The command-not-found hot path only classifies input and performs exact local
lookups. It renders every valid hit in the same fixed order and maps each
backend to a static install-command template; it does not call Search, Install,
package-manager executables, registries, or the network.

Aggregate CNF telemetry is local and bounded. Each event contains only an
epoch, hit/miss state, and fixed-order backend set; command text and arguments
never enter the file. Reports calculate 7-day, 30-day, or retained-history hit
rates and backend contributions without uploading data. Statistics failures
are best-effort and cannot change the CNF recommendation result.

Command-level miss data is a separate opt-in channel. Its marker and bounded
history are private local files; records contain an epoch and the classified
missing command, never its arguments. Disabling tracking preserves existing
history, while reset removes history without silently changing the user's
opt-in choice. Reporting validates storage and caps output before sorting.

Zsh completion mirrors the full Index command surface through literal arrays
and word-position routing. Backend, period, tracking-action, and common-limit
candidates are static; completion never executes MDTK, package managers, Git,
filesystem discovery, or network requests.

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

Tests live in `tests/` and run with `shellspec` under zsh. Every implemented module has focused specs, and every bug fix requires a regression test (see `.ai/TESTING.md`). `tests/bin/mdtk_spec.sh` covers entry-point and dispatcher wiring; module behavior lives in the corresponding test directories.

## Where the spec lives

The machine-precise, AI-facing rules are in `.ai/`:

- `.ai/ARCHITECTURE.md` — the canonical architecture rules.
- `.ai/MASTER_PROMPT.md` — core principles.
- `.ai/STYLE_GUIDE.md` — coding style.

This document is the narrative. When they disagree, the `.ai/` version wins.
