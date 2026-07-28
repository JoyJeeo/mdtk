## Current issue

(none — installation issues #021–#025 are closed; #012 Doctor remains queued
and must be opened explicitly before implementation.)

---

## Queue (next, not started)

- #012 Doctor — `src/doctor/doctor.zsh` (v0.2 per ROADMAP).

---

## Closed

### #025 Uninstall hook cleanup at end of zshrc — **closed**

- Managed hooks at `.zshrc` EOF no longer make uninstall stop early.
- Regression coverage verifies link, hook, cache, configuration, and marked
  managed-root removal together.
- Tests: 131 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #024 Silent command-index build — **closed**

- Command-index builds no longer print stale Homebrew JSON while processing
  multiple formulae.
- Multi-formula regression coverage verifies silent stdout and unchanged index
  contents.
- Tests: 130 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #023 Homebrew-bin install fallback — **closed**

- Installer prefers the active writable Homebrew bin directory.
- Apple Silicon `/opt/homebrew/bin` behavior has regression coverage.
- Tests: 129 examples green; DoD met; reviewed; merged.

### #022 Remote-friendly installer — **closed**

- Added local delegation and `curl ... | zsh` remote bootstrap modes.
- Managed XDG checkout is atomic, marked, origin/branch verified, and updatable.
- Existing checkout hooks migrate with a required backup.
- Tests: 128 examples green; DoD met; reviewed; merged.

### #021 One-command uninstall — **closed**

- Added confirmation, yes, keep-config, and dry-run modes.
- Removes only validated MDTK-managed links, hook, data, and marked source.
- Tests: 118 examples green; DoD met; reviewed; merged.

### #020 Planning metadata synchronization — **closed**

- PRODUCT and ROADMAP record shipped v0.1 Homebrew capabilities.
- ROADMAP and TASK consistently place Doctor in v0.2.
- Tests: 107 examples green; DoD met; reviewed; merged.

### #019 Human documentation state synchronization — **closed**

- Corrected runtime, module-status, backend, install, and test instructions.
- Labeled historical planning transcripts as non-authoritative.
- Tests: 104 examples green; DoD met; reviewed; merged.

### #018 Developer bootstrap ShellCheck directive cleanup — **closed**

- Removed an accidental malformed ShellCheck directive comment.
- Added a `make lint` regression spec.
- Tests: 101 examples green; DoD met; reviewed; merged.

### #017 CNF command-index architecture boundary — **closed**

- Index is a private CNF component with no public dispatch function.
- `mdtk index` routes through CNF's sole module dispatch entry point.
- Tests: 100 examples green; DoD met; reviewed; merged.

### #016 Search dead snapshot helper removal — **closed**

- Removed the unused snapshot helper, cache claim, and path dependency.
- Homebrew search behavior and CLI output are unchanged.
- Tests: 100 examples green; DoD met; reviewed; merged.

### #015 Config path utility adoption — **closed**

- Config delegates XDG/HOME path resolution to utils/path.
- Added regression coverage for the HOME fallback path.
- Tests: 100 examples green; DoD met; reviewed; merged.

### #014 Logger color utility adoption — **closed**

- Logger delegates ANSI sequences and shared no-color policy to utils/color.
- Existing Logger-specific no-color behavior remains compatible.
- Tests: 99 examples green; DoD met; reviewed; merged.

### #013 Logger test environment isolation — **closed**

- Logger specs clear inherited mode variables before every example.
- Full suite passes both normally and with inherited `NO_COLOR=1`.
- DoD met; reviewed; merged.

### #011 Install Script — **closed**

Implemented the user-facing installer.

- scripts/install.sh: macOS/zsh guard, brew detect (prints official
  install cmd if missing, no auto network pipe), symlink mdtk onto
  first writable on-PATH dir, append source-hook to ~/.zshrc
  (idempotent + backup), initial mdtk index build, friendly finish.
- Tests: tests/install/install_spec.sh (6 examples, isolated
  HOME/PATH, brew mocked).
- DoD met; reviewed; merged.

### #010 command_not_found_handler — **closed**

Implemented the command-not-found handler module.

- src/cnf/cnf.zsh: index lookup first, homebrew backend fallback,
  friendly Found/Run recommendation.
- scripts/mdtk.zsh: defines command_not_found_handler to call mdtk cnf.
- CLI: mdtk cnf <cmd>. Tests mock brew + prebuilt index; 6 examples green.
- DoD met; reviewed; merged.

### #009 Command Index — **closed**

Implemented the Command Index module.

- Builds command=formula index from brew list + aliases; persisted to
  cache dir. lookup by command name.
- CLI: mdtk index {build|lookup|path|help}. Sources utils/path +
  homebrew backend. Dispatcher routes `index`.
- Tests mock brew; 8 examples, all green.
- DoD met; reviewed; merged.

### #008 Install Recommendation — **closed**

Implemented the Install module.

- mdtk install <cmd>: finds formula via homebrew provides; prints
  Found/Run recommendation. Does NOT auto-install in v0.1.
- Sources homebrew backend (leaf). Tests mock brew; 5 examples green.
- DoD met; reviewed; merged.

### #007 Search Engine — **closed**

Implemented the Search module.

- Queries the Homebrew backend; prints formulae one/line.
- CLI: mdtk search <query>. Sources utils/path + homebrew backend.
- Tests mock brew; 5 examples, all green.
- DoD met; reviewed; merged.

### #006 Homebrew Backend — **closed**

Implemented the Homebrew backend.

- available/search/provides/install; leaf (no module calls).
- provides: same-name formula first, then alias scan via brew info JSON.
- Tests mock brew (function override); 10 examples, all green.
- DoD met; reviewed; merged.

### #005 Command Dispatcher — **closed**

Enhanced the dispatcher.

- Added `cnf` route -> src/cnf/cnf.zsh (stub now, real in #010).
- Refreshed help text (landed modules + cnf).
- No behavior change to version/help/unknown/module routing.
- Tests: extended tests/bin/mdtk_spec.sh (help has cnf; cnf route).
- DoD met; reviewed; merged.

### #004 Cache — **closed**

Implemented the Cache module.

- XDG-aware cache dir; one file per name; names restricted to [a-z0-9_]+.
- API: get/set/clean; CLI: mdtk cache {get|set|clean|list|path|help}.
- Sources utils/path (library, allowed).
- Tests: tests/cache/cache_spec.sh (14 examples, all green).
- DoD met; reviewed; merged.

### #003 Utils — **closed**

Implemented the Utils library (stateless shared helpers).

- path: root/config/cache_dir/cache_file (XDG-aware).
- color: enabled/for/reset (honors NO_COLOR + MDTK_NO_COLOR).
- shell: zsh_version/has_option/env_get (set-u-safe).
- Tests: tests/utils/utils_spec.sh (14 examples, all green).
- DoD met; reviewed; merged.

### #002 Config — **closed**

Implemented the Config module.

- XDG-aware config file at $XDG_CONFIG_HOME/mdtk/config (or $HOME/.config/mdtk/config).
- API: mdtk_config_get / mdtk_config_set; CLI mdtk config {get|set|list|path|help}.
- Missing key returns 1; set overwrites or appends; isolated XDG in tests.
- Tests: tests/config/config_spec.sh (11 examples, all green).
- DoD met; reviewed; merged.

### #001 Logger — **closed**

Implemented the Logger module.

- Levels: INFO / SUCCESS / WARNING / ERROR / DEBUG.
- Color by default; NO_COLOR env / --no-color disable.
- --quiet (ERROR only); --debug / MDTK_DEBUG=1 for DEBUG.
- Output format: [LEVEL] message.
- Per-level functions mdtk_logger_<level> exposed for other modules.
- Tests: tests/logger/logger_spec.sh (18 examples, all green).
- DoD met; reviewed; merged.
