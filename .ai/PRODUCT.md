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

The v0.1 line ships structured logging, configuration, cache, Homebrew search,
install recommendations, a command index, command-not-found support, managed
installation/update workflows, and the user installer. Remaining planned
capabilities ship only at their roadmap milestone (see `.ai/ROADMAP.md`).

### Shipped in v0.1

- Smart command not found
- Homebrew search
- Install recommendation
- Command cache
- Structured logs
- Configuration system

### Shipped in v0.1.1

- Safe one-command uninstall
- Remote-friendly XDG installer bootstrap
- Branch/tag ref installation
- Managed automatic updates
- Pasted-text command-not-found protection

### Shipped in v0.1.2

- Complete offline Homebrew executable index
- Fast exact binary command lookup
- Non-blocking command-not-found index misses

### Shipped in v0.1.3

- Stable latest-Tag user installation and updates
- Explicit coder channel for `main`
- Unchanged managed-install detection

### Shipped in v0.1.4

- Correct unchanged-install detection for annotated stable tags

### Shipped in v0.1.5

- Consistent no-icon colored status output across user and developer workflows
- Plain, script-friendly output retained for command data

### Shipped in v0.2.0

- Read-only developer environment diagnostics
- Native Zsh command and option completion

### Shipped in v0.3.0

- XDG-aware user plugin discovery
- Explicit, lazy plugin execution
- Native Plugin command completion

### Shipped in v0.4.0

- pip, cargo, conda, and npm package-manager backends
- Explicit backend selection for package search and install recommendations
- Static backend option and value completion

### Planned

- Production hardening and v1.0 release

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
