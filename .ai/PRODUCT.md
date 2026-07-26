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

## Planned features

> "Planned" = on the roadmap (see `.ai/ROADMAP.md`). None of these ship until their milestone. The toolkit currently contains only the infrastructure skeleton plus module stubs.

- Smart command not found
- Homebrew search
- Install recommendation
- Command cache
- Developer doctor
- Environment diagnostics
- Better logs
- Plugin system
- Configuration system

## Package-manager backends

The canonical set of backends MDTK will support. (The same list appears in `.ai/ARCHITECTURE.md` and `.ai/ROADMAP.md`; keep them in sync when changing.)

- Homebrew  (v0.2)
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
