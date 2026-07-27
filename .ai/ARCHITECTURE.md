# Architecture

## Flow

```
Entry (bin/mdtk)
        ↓
Command Dispatcher (src/dispatcher.zsh)
        ↓
Modules (src/<module>/<module>.zsh)
  Logger · Config · Cache · Search · Install · Doctor · Plugin
        ↓
Backends (src/backends/*.zsh)
  Homebrew · pip · conda · cargo · npm
```

Shared, stateless helpers live in `src/utils/` and project-wide
read-only constants live in `src/core/constants.zsh`. Neither is a
module: they have no dispatch function and never call back upward.

## Source tree

```
src/
├── version.zsh          # MDTK_VERSION constant
├── dispatcher.zsh       # command dispatcher (infrastructure)
├── core/
│   └── constants.zsh    # project-level read-only constants
├── utils/               # stateless shared helpers
│   ├── color.zsh        # ANSI color / NO_COLOR
│   ├── path.zsh         # path resolution (no hardcode)
│   └── shell.zsh        # zsh version/option detection
├── backends/            # package-manager wrappers (leaves)
│   └── *.zsh
└── <module>/            # one directory per feature module
    └── <module>.zsh     # exposes mdtk_<module>_dispatch
```

## Rules

1. **Modules never call each other directly.** All routing goes through the dispatcher. If module A needs something module B does, the user runs `mdtk B …`; modules do not source each other.
2. **Backends never call modules.** A backend is a leaf: it is called by a module (e.g. `search`, `install`) and calls an external tool (`brew`, `pip`, …). It never reaches back up into a module.
3. **Direction is strictly downward:** Entry → Dispatcher → Modules → Backends. No upward or sideways calls.
4. **Shared utilities live in `src/utils/`** and are treated as a library, not a module. A utility function does one small, pure thing (no I/O policy, no user-facing messages) and is sourced by whoever needs it. Utilities are stateless and have no dispatch function.
5. **Modules are independent and stateless across calls.** Persistent state (config values, caches) is read from and written to disk by the `config` / `cache` modules, never held in module globals.
6. **One responsibility per file.** A module's primary file exposes exactly one dispatch entry point: `mdtk_<name>_dispatch "$@"`. A complex module may source private, same-directory component files; those components must stay within the module's responsibility, expose no public dispatch function, and never be routed directly by the dispatcher.

## Loading

Modules and backends are sourced on demand at call time, not at shell startup. This keeps `mdtk` startup fast regardless of how large the toolkit grows (see `.ai/MASTER_PROMPT.md` → Performance).

## The one rule to remember

> Modules cannot call each other directly. Everything goes through the dispatcher.
