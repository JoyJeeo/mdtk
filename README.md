# mdtk

**Mac Developer Toolkit (MDTK)** — a developer toolkit for macOS, written in zsh.

Better terminal experience for developers, AI engineers, Linux-to-macOS switchers, students, and heavy terminal users.

> **Status:** infrastructure only. Feature modules (Logger, Config, Cache, Search, ...) are stubs; each ships when its task in `.ai/TASK.md` is opened. See `.ai/ROADMAP.md`.

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
src/modules/*.zsh     one stub per module (logger, config, cache, ...)
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

## For AI coding agents

Read `AGENTS.md` and the `.ai/` specs **before** writing any code. Never implement outside the current task in `.ai/TASK.md`.
