# Product Requirement

## Identity

- **Project name:** Mac Developer Toolkit
- **Short name:** MDTK
- **Mission:** Provide the best terminal experience for macOS developers.

## Design goals

- Simple
- Fast
- Friendly
- Reliable

## Capabilities

The v0.1 release ships structured logging, configuration, cache, Homebrew
search, install recommendations, a command index, command-not-found support,
and the user installer. Remaining planned capabilities ship only at their
roadmap milestone (see `.ai/ROADMAP.md`).

### Shipped in v0.1

- Smart command not found
- Homebrew search
- Install recommendation
- Command cache
- Structured logs
- Configuration system

### Planned

- Developer doctor / environment diagnostics (v0.2)
- Plugin system (v0.3)
- Additional package-manager backends (v0.4)

## Package-manager backends

The canonical set of backends MDTK will support. (The same list appears in `.ai/ARCHITECTURE.md` and `.ai/ROADMAP.md`; keep them in sync when changing.)

- Homebrew  (v0.1)
- pip       (v0.4)
- conda     (v0.4)
- cargo     (v0.4)
- npm       (v0.4)
- docker    (future, post-v1.0)
- sdkman    (future, post-v1.0)

## Non-goals

- Not a shell framework (does not manage prompt/plugins/`~/.zshrc`).
- Not a replacement for Homebrew (delegates installs to the backend).
- macOS only.
