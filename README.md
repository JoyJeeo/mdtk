# mdtk

**Mac Developer Toolkit (MDTK)** — a developer toolkit for macOS, written in zsh.

Better terminal experience for developers, AI engineers, Linux-to-macOS switchers, students, and heavy terminal users.

> **Status:** v0.1.0 released. The toolkit provides structured logging, config, a cache, a Homebrew backend, package search, install recommendations, a command→formula index, and a smart command-not-found handler. See `.ai/ROADMAP.md` for what's next (Doctor, Plugin, more backends).

---

## Requirements

- macOS (Apple Silicon or Intel)
- zsh (default on macOS; you have 5.x)
- conda with a `mdtk` environment

## Quick start

```sh
# 1. Enter the project's conda env
conda activate mdtk

# 2. Bootstrap (installs shellspec into the env + symlinks the mdtk command)
./install.zsh

# 3. Sanity check
mdtk version
mdtk help

# 4. Run tests
make test
```

After `install.zsh`, the `mdtk` command points into this repo, so editing source under `src/` takes effect immediately.

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
docs/                 human-facing docs (vision, faq, architecture, development)
.ai/                  project specifications (read these first)
AGENTS.md             instructions for AI coding agents
```

## Documentation

- **`docs/vision.md`** — the why behind MDTK.
- **`docs/architecture.md`** — how the pieces fit (narrative).
- **`docs/development.md`** — how to build, test, and contribute.
- **`docs/faq.md`** — common questions.
- **`.ai/`** — the authoritative spec (read before coding).
- **`CHANGELOG.md`** — what changed and why.

## Status

v0.1.0 released. Feature modules shipped: Logger, Config, Cache, Utils, Dispatcher, Homebrew backend, Search, Install, Command Index, command-not-found handler. See `.ai/ROADMAP.md` for what's next.

## Smart command-not-found

Source the shell hook in your `~/.zshrc`:

```sh
source /path/to/mdtk/scripts/mdtk.zsh
```

Now when you type an uninstalled command, zsh calls `mdtk cnf <cmd>`,
which looks it up and prints a recommendation:

```
$ rg file
Found: the "rg" command is provided by the "ripgrep" formula.
Run: brew install ripgrep
```

Build the command index once (and after installing new formulae):

```sh
mdtk index build
```

## For AI coding agents

Read `AGENTS.md` and the `.ai/` specs **before** writing any code. Never implement outside the current task in `.ai/TASK.md`.
