# Roadmap

> The source of truth for what ships when. When a milestone changes, also update `.ai/PRODUCT.md` (backends) and `.ai/TASK.md` (current focus).

## v0.1 — Foundation & Homebrew assistance (shipped)

- Logger
- Config
- Cache
- Utils
- Search
- Homebrew backend
- Command index
- Install recommendation
- command-not-found handler
- User installer

## v0.2 — Diagnostics (shipped)

- Doctor
- Native Zsh command completion

## v0.3 — Extensibility (shipped)

- Plugin

## v0.4 — More backends (shipped)

- pip backend
- cargo backend
- conda backend
- npm backend

## v1.0 — Production release (shipped)

- Production release

## v1.1 — Multi-backend offline command index (scheduled)

- Repository-maintained popular CLI catalogs for pip, npm, Cargo, and conda
- Bounded, atomic local index builds for every supported package backend
- Offline CNF lookup across all local indexes with every match shown
- Local aggregate hit-rate statistics and opt-in detailed miss tracking
- Native completion, installer integration, documentation, and release

## Post-v1.1 (future, not yet scheduled)

- docker support
- sdkman support
