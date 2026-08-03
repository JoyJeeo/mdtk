## Current issue

### #050 Dispatcher colored errors — **closed**

- Target: `src/dispatcher.zsh`.
- Color unknown-command errors and recovery guidance only; preserve stdout,
  help/version output, routing, `NO_COLOR`, and exit statuses.
- Tests: 210 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

---

## Queue (next, not started)

- #051 Developer-installer colored presentation — `scripts/dev-install.zsh`.
- #012 Doctor — `src/doctor/doctor.zsh` (v0.2 per ROADMAP).

---

## Closed

### #049 Uninstall colored status and errors — **closed**

- Removal plans, cancellation, safety errors, and completion use semantic
  colors without changing prompts or `.zshrc` content.
- Tests: 209 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #048 Search colored errors — **closed**

- Search prerequisite errors use ERROR; formula/cask results remain unchanged.
- Tests: 208 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #047 Install-recommendation colored status and errors — **closed**

- Direct recommendations match CNF colors; Homebrew absence uses ERROR.
- Recommendation-only behavior and exit statuses remain unchanged.
- Tests: 208 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #046 CNF/index colored status and errors — **closed**

- Recommendations/misses and index errors use shared aligned labels; exact
  formula lookup remains silent and plain.
- Tests: 201 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed, including two-second lookup bounds.

### #045 Update colored presentation — **closed**

- Managed-update status and errors use shared aligned level colors.
- Option parsing, help, installer delegation, stderr, and `NO_COLOR` remain
  unchanged.
- Tests: 199 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #044 Installer colored presentation — **closed**

- Remote and checkout installers use aligned INFO, SUCCESS, WARNING, and ERROR
  labels without icons; `OK` and `WARN` abbreviations were removed.
- Stderr routing and `NO_COLOR` behavior are preserved.
- Tests: 198 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #043 Logger colored presentation — **closed**

- Logger now reuses the shared no-icon formatter with aligned colored labels.
- Quiet, debug, `--no-color`, `NO_COLOR`, and public functions are preserved.
- Tests: 196 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #042 Shared colored log labels — **closed**

- Added one shared, no-icon formatter for INFO, SUCCESS, WARNING, ERROR, and
  DEBUG labels using the existing level colors.
- Preserved plain, ANSI-free labels under `NO_COLOR` and `MDTK_NO_COLOR`.
- Tests: 196 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #041 Release version 0.1.4 — **closed**

- Published the annotated-tag reinstall fix as `v0.1.4`.
- Created and pushed an annotated tag and GitHub Release.
- Updated the local managed copy and verified repeated stable updates skip
  setup.
- Tests: 189 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; released.

### #039 Release version 0.1.3 — **closed**

- Published the stable/coder installation-channel changes as `v0.1.3`.
- Created and pushed an annotated tag and GitHub Release.
- Reinstalled the local managed copy and verified stable updates.
- Tests: 188 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; released.

### #040 Annotated-tag reinstall detection — **closed**

- Dereference annotated `FETCH_HEAD` tags before comparing with the installed
  commit so unchanged stable versions skip setup.
- Annotated-tag regression coverage verifies repeated stable installs skip
  setup when the tag-object SHA differs from its commit SHA.
- Tests: 189 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #038 Coder install channel naming — **closed**

- Rename the developer install channel value from `development` to `coder`.
- Keep `mdtk update --coder` unchanged.
- Update installer behavior, documentation, tests, and CHANGELOG consistently.
- Tests: 188 examples green; DoD met; reviewed; merged.

### #037 Stable and development install channels — **closed**

- Ordinary remote installs and updates select the newest semantic release tag.
- Developers select latest `main` with `MDTK_INSTALL_CHANNEL=coder` or
  `mdtk update --coder`.
- Reinstalling an unchanged managed ref skips setup; existing tags now have
  GitHub Releases.
- Tests: 188 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #036 Release version 0.1.2 — **closed**

- Runtime, README, development, PRODUCT, and CHANGELOG metadata consistently
  describe version `0.1.2` dated 2026-07-29.
- The release commit is intended for annotated tag `v0.1.2` only; no GitHub
  Release is created.
- Tests: 183 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #035 Exact binary index prefix matching — **closed**

- Binary lookup uses the complete `command=` key, so exact commands are not
  hidden by lexically earlier prefix neighbors.
- Regression coverage verifies both direct index lookup and CNF recommendation.
- Tests: 183 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #034 Fast command-index lookup — **closed**

- Full indexes use deterministic byte ordering and exact binary lookup instead
  of scanning every record.
- Missing, malformed, unreadable, empty, and indexes above 8 MiB fail fast
  without Homebrew or network access.
- Tests: 181 examples green in normal and `NO_COLOR=1` environments; 20,000
  record hit/miss limits and real full-index performance verified; reviewed;
  merged.

### #033 Full Homebrew command index — **closed**

- `mdtk index build` uses Homebrew's complete executable metadata, including
  commands from formulae that are not installed.
- Index replacement is atomic; missing or malformed metadata preserves the
  previous cache, and CNF misses never wait for Homebrew or the network.
- Tests: 176 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #032 Short command fallback guard — **closed**

- One- and two-character commands retain fast local-index recommendations but
  skip broad Homebrew fallback after an index miss.
- Short misses print an explicit manual-search command; three-character and
  longer commands preserve existing fallback behavior.
- Tests: 171 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #031 Release version 0.1.1 — **closed**

- Runtime, README, development, PRODUCT, and CHANGELOG metadata consistently
  describe version `0.1.1` dated 2026-07-29.
- The release commit is intended for annotated tag `v0.1.1` only; no GitHub
  Release is created.
- Tests: 168 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #030 Transactional managed ref activation — **closed**

- Checkout, target setup, and ref metadata commit now succeed as one managed
  activation transaction or restore the previous installation.
- Failed existing updates restore HEAD/ref and rerun prior setup; failed first
  installs remove only the new marker-validated checkout.
- Tests: 168 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #029 Managed automatic update — **closed**

- `mdtk update` updates marked XDG managed installations to `main` or an
  optional branch/tag ref through the installer workflow.
- The managed checkout's verified origin is preserved, setup and index build
  rerun, and ordinary source checkouts are refused.
- Tests: 165 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #028 Installer managed ref selection — **closed**

- `MDTK_INSTALL_REF` installs and records branch or tag refs through curl.
- Existing origin-verified managed checkouts switch refs without forcing away
  local tracked modifications; legacy installations gain ref metadata.
- Unsafe refs and Git failures are rejected without changing recorded state.
- Tests: 150 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #027 Full command-not-found input classification — **closed**

- The zsh hook forwards the complete missing-command field to CNF.
- A bounded, I/O-free classifier separates command-shaped input from pasted
  headings, lists, prose, and oversized text before Homebrew fallback.
- Options, paths, assignments, one plain argument, digits, punctuation, and
  CJK arguments retain command recommendation behavior.
- Tests: 144 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #026 Command-not-found pasted-text guard — **closed**

- Numeric section headings and pasted list markers return before any Homebrew
  fallback query.
- Common executable names containing digits and punctuation remain searchable.
- Tests: 134 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

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
