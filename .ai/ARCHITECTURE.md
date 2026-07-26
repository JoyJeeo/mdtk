# Architecture

Entry

↓

Command Dispatcher

↓

Modules

- Logger
- Config
- Cache
- Search
- Install
- Doctor
- Plugin

↓

Backends

- Homebrew
- pip
- conda
- cargo
- npm

---

Rules

Modules cannot call each other directly.
Everything goes through the dispatcher.
