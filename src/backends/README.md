# Backends

The layer *below* modules. A backend wraps a single external package manager
and exposes a small, uniform interface that modules like `search` and
`install` call into.

## Rules (from .ai/ARCHITECTURE.md)

- Direction is strictly downward: **a module calls a backend; a backend never
  calls a module**, and never reaches back up to the dispatcher.
- A backend is a leaf: it talks to one external tool (`brew`, `pip`, …) and
  returns data. No user-facing messages, no state across calls.

## Canonical backend list

The authoritative list lives in `.ai/PRODUCT.md`. Keep this file in sync with
it. Current plan:

| Backend   | Milestone        |
| --------- | ---------------- |
| homebrew  | v0.2             |
| pip       | v0.4             |
| conda     | v0.4             |
| cargo     | v0.4             |
| npm       | v0.4             |
| docker    | post-v1.0        |
| sdkman    | post-v1.0        |

## Status

Phase 3 (source-tree design): each `*.zsh` here is a comments-only placeholder
describing the backend's responsibility and expected interface. No backend is
implemented. Implementations land with their milestone (`.ai/ROADMAP.md`).
