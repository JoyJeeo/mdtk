## Current issue

### #082 Installer multi-backend index integration — `scripts/install.sh` — **closed**

- Build every shipped local index during installation and managed updates.
- Keep installation usable when an optional backend index cannot be rebuilt.
- Tests: 505 examples green in normal and `NO_COLOR=1` environments; release
  gate and DoD passed; senior review passed with no findings.

---

## Queued

### #083 Catalog validation tooling — `scripts/catalog-check.zsh`

- Add a repeatable, offline catalog validation command for contributors.
- Document build/refresh semantics, offline lookup, privacy, capacity limits,
  and the manual catalog review workflow alongside the tool.

### #084 Release version 1.1.0

- Synchronize version and release metadata, run the complete offline release
  gate, review, tag, publish, and verify v1.1.0.

---

## Closed

### #081 Multi-backend index completion — `completions/_mdtk` — **closed**

- Completed build, refresh, lookup, path, statistics, tracking, miss-report,
  backend, period, action, and limit arguments with static definitions.
- Kept completion free of MDTK, package-manager, Git, filesystem-discovery,
  and network calls.
- Tests: 501 examples green in normal and `NO_COLOR=1` environments; release
  gate and DoD passed; senior review passed with no findings; merged.

### #080 Opt-in detailed index misses — `src/cnf/index_stats.zsh` — **closed**

- Kept command-level miss recording disabled until explicit opt-in.
- Added enable/disable/status, private 256 KiB-bounded command-only storage,
  count-sorted limited reports, and reset without changing opt-in state.
- Kept arguments out of storage, all data local-only, and recording best-effort
  so statistics never change CNF results.
- Tests: 488 examples green in normal and `NO_COLOR=1` environments; release
  gate and DoD passed; senior review passed after shared-validator refactoring;
  merged.

### #079 Aggregate local index statistics — `src/cnf/index_stats.zsh` — **closed**

- Added 1 MiB-bounded local hit/miss events without command names or arguments.
- Added default 30-day, 7-day, and retained-history reports with total hit rate
  and fixed-order per-backend contributions.
- Kept statistics best-effort, private, local-only, and independent of CNF
  results; used Zsh built-ins on the recording hot path.
- Tests: 462 examples green in normal and `NO_COLOR=1` environments; release
  gate and DoD passed; senior review passed after hot-path optimization; merged.

### #078 Multi-backend offline CNF recommendations — `src/cnf/cnf.zsh` — **closed**

- Queried every local index without package-manager or network access and
  displayed all matches in fixed product order.
- Added backend-appropriate install commands while preserving legacy Homebrew
  recommendation wording and existing input classification.
- Tests: 443 examples green in normal and `NO_COLOR=1` environments; release
  gate and DoD passed; senior review passed with no findings; merged.

### #077 Multi-backend index build and refresh — `src/cnf/index.zsh` — **closed**

- Added all-backend default build, explicit backend selection, and a manual
  `refresh` alias.
- Kept Homebrew complete metadata and legacy-cache compatibility; compiled
  the four shipped catalogs offline.
- Added per-backend failure isolation, continuation, nonzero partial status,
  secure atomic replacements, and an atomic build manifest.
- Tests: 435 examples green in normal and `NO_COLOR=1` environments; release
  gate and DoD passed; senior review passed with no findings; merged.

### #076 Popular CLI catalog compiler — `src/cnf/catalog.zsh` — **closed**

- Added reviewable repository catalogs for pip, npm, Cargo, and conda.
- Added offline validation, ranking, deduplication, byte sorting, capacity
  checks, and atomic compilation with old-index preservation.
- Tests: 416 examples green in normal and `NO_COLOR=1` environments; release
  gate and DoD passed; senior review passed with no findings; merged.

### #075 Multi-backend index storage and lookup — `src/cnf/index.zsh` — **closed**

- Added bounded per-backend index paths and a manifest contract below the XDG
  cache.
- Preserved exact lookup and legacy Homebrew CLI/cache compatibility.
- Added selected-backend and all-backend queries in fixed product order.
- Tests: 391 examples green in normal and `NO_COLOR=1` environments; release
  gate and DoD passed; senior review passed with no findings; merged.

### #074 v1.1 multi-backend offline-index planning — **closed**

- Target: authoritative planning metadata and its regression coverage.
- Scheduled v1.1.0 as a backward-compatible multi-backend offline-index
  milestone without changing the v1.0 runtime.
- Recorded repository-maintained `popular` catalogs, the 80 MiB hard limit,
  all-match offline lookup order, local-only statistics, opt-in detailed
  misses, and per-backend failure isolation.
- Tests: 371 examples green in normal and `NO_COLOR=1` environments; release
  gate and senior review passed with no findings; merged.

### #073 Production release version 1.0.0 — **closed**

- Publish the complete scheduled MDTK roadmap as `v1.0.0`.
- Synchronize runtime, README, development, PRODUCT, ROADMAP, tests, and
  CHANGELOG metadata.
- Run the complete offline production release-readiness gate.
- Create and push an annotated `v1.0.0` tag and non-prerelease GitHub Release.
- Verify stable-channel selection, published Release, and an empty scheduled
  backlog.
- Tests: production release gate passed with 366 examples in normal and
  `NO_COLOR=1` environments, checkout Smoke, syntax and marker scans; senior
  review passed; released.

### #072 Production release-readiness gate — `scripts/release-check.zsh` — **closed**

- Target: `scripts/release-check.zsh` and contributor release tooling.
- Provide one repeatable, offline gate for syntax, normal/no-color suites,
  checkout Smoke, and forbidden unfinished markers in active runtime files.
- Fail immediately and preserve each underlying command's status.
- Synchronize stale maintained skeleton/stub wording.
- Tests: success and each failure boundary with mocked tools, real gate run,
  docs, CHANGELOG, DoD, review.
- Tests: release gate passed with 363 examples in normal and `NO_COLOR=1`
  environments, checkout Smoke, and marker scan; senior review passed after
  marker-boundary and Git-error propagation fixes.

### #071 Release version 0.4.0 — **closed**

- Publish pip, cargo, conda, and npm backends plus Search/Install integration
  and completion as `v0.4.0`.
- Synchronize runtime, user/developer docs, PRODUCT, ROADMAP, tests, and
  CHANGELOG metadata.
- Create and push an annotated `v0.4.0` tag and GitHub Release.
- Verify stable-channel selection and the published Release.
- Tests: normal and `NO_COLOR=1` suites, DoD, review, release verification.
- Tests: 355 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed after maintained-doc regression synchronization;
  released.

### #070 Package-backend completion — `completions/_mdtk` — **closed**

- Target: `completions/_mdtk`.
- Complete Search/Install `--backend` and all supported backend values.
- Keep completion static and free of MDTK, package-manager, filesystem, and
  network calls.
- Tests: both commands/options/values, no external calls, performance, docs,
  CHANGELOG, DoD, review.
- Tests: 353 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed with no findings.

### #069 Install-recommendation backend selection — `src/install/install.zsh` — **closed**

- Target: `src/install/install.zsh`.
- Preserve Homebrew recommendations by default and add explicit `--backend`
  selection for homebrew, pip, cargo, conda, and npm.
- Print backend-appropriate install commands without installing anything.
- Tests: every backend, hit/miss/unavailable/failure/unknown, empty/Unicode/
  large input, default compatibility, docs, CHANGELOG, DoD, review.
- Tests: 350 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed with no findings.

### #068 Search backend selection — `src/search/search.zsh` — **closed**

- Target: `src/search/search.zsh`.
- Preserve Homebrew as the default and add explicit `--backend` selection for
  homebrew, pip, cargo, conda, and npm.
- Route through fixed backend cases without dynamic evaluation.
- Tests: every backend, unavailable/failing/unknown backends, empty/Unicode/
  large queries, default compatibility, docs, CHANGELOG, DoD, review.
- Tests: 340 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed after restoring the Homebrew-specific error contract.

### #067 npm package-manager backend — `src/backends/npm.zsh` — **closed**

- Target: `src/backends/npm.zsh`.
- Detect npm, search the registry, resolve exact same-name CLI packages through
  their `bin` metadata, and delegate global installation.
- Keep the backend a leaf and preserve arguments without evaluation.
- Tests: parsing/search/provides/install, failures, empty/Unicode/large input,
  injection safety, docs, CHANGELOG, DoD, review.
- Tests: 327 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed with no findings.

### #066 conda package-manager backend — `src/backends/conda.zsh` — **closed**

- Target: `src/backends/conda.zsh`.
- Detect conda, search configured channels, resolve exact same-name packages
  as a best-effort command mapping, and delegate installation.
- Keep the backend a leaf and preserve arguments without evaluation.
- Tests: parsing/search/provides/install, failures, empty/Unicode/large input,
  injection safety, docs, CHANGELOG, DoD, review.
- Tests: 312 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed with no findings.

### #065 cargo package-manager backend — `src/backends/cargo.zsh` — **closed**

- Target: `src/backends/cargo.zsh`.
- Detect Cargo, search crates.io, resolve exact same-name binaries as a
  best-effort mapping, and delegate installation.
- Keep the backend a leaf and preserve arguments without evaluation.
- Tests: search/provides/install, failures, empty/Unicode/large input,
  injection safety, docs, CHANGELOG, DoD, review.
- Tests: 297 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed with no findings.

### #064 pip package-manager backend — `src/backends/pip.zsh` — **closed**

- Target: `src/backends/pip.zsh`.
- Detect `pip3`/`pip`, query PyPI package versions, resolve same-name console
  commands as a documented best-effort mapping, and delegate installation.
- Keep the backend a leaf; preserve arguments without shell evaluation.
- Tests: tool selection, search/provides/install, failures, empty/Unicode/large
  input, injection safety, docs, CHANGELOG, DoD, review.
- Tests: 283 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed after independent empty-input coverage fixes.

### #063 Release version 0.3.0 — **closed**

- Publish the Plugin system and its native completion as `v0.3.0`.
- Synchronize runtime, README, development, PRODUCT, ROADMAP, tests, and
  CHANGELOG metadata.
- Create and push an annotated `v0.3.0` tag and GitHub Release.
- Verify stable-channel selection and the published Release.
- Tests: normal and `NO_COLOR=1` suites, DoD, review, release verification.
- Tests: 267 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed after planning-regression and Vision fixes; released.

### #062 Native Plugin command completion — `completions/_mdtk` — **closed**

- Target: `completions/_mdtk`.
- Complete Plugin subcommands and positional plugin names/arguments statically.
- Never scan plugin directories or invoke MDTK/external commands.
- Preserve existing completion registration, idempotency, and performance.
- Tests: subcommands, positions, no I/O/external calls, docs, CHANGELOG, DoD,
  review.
- Tests: 265 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed with no findings.

### #061 Plugin dispatcher presentation — `src/dispatcher.zsh` — **closed**

- Target: `src/dispatcher.zsh`.
- Present Plugin as an implemented command and remove the obsolete global
  unimplemented-command notice.
- Preserve routing, help formatting, output channels, and exit statuses.
- Tests: implemented help text, existing routes, docs, CHANGELOG, DoD, review.
- Tests: 263 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed with no findings.

### #060 Plugin discovery and execution — `src/plugin/plugin.zsh` — **closed**

- Target: `src/plugin/plugin.zsh`.
- Discover user plugins from the XDG data directory without shell-startup I/O.
- List plugins, print the plugin directory, and explicitly run one plugin.
- Validate plugin names and files; reject traversal, symlinks, missing entry
  points, and load failures with actionable errors.
- Preserve plugin exit codes and pass arguments without re-evaluation.
- Tests: success, failure, empty input, whitespace/Unicode names, large plugin
  sets, deterministic listing, docs, CHANGELOG, DoD, review.
- Tests: 263 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed after return-contract and empty-name coverage fixes.

### #059 Planning and maintained-documentation synchronization — **closed**

- Target: planning metadata and maintained contributor/user documentation.
- Record native Zsh completion in the shipped v0.2 roadmap milestone.
- Correct stale backend implementation status and managed-update guidance.
- Refresh planning regression tests and smoke-test descriptions.
- Update CHANGELOG; run normal and `NO_COLOR=1` suites; meet DoD; review.
- Tests: 241 examples green in normal and `NO_COLOR=1` environments; DoD met;
  senior review passed after the test-helper documentation fix.

### #058 Release version 0.2.0 — **closed**

- Publish Doctor and native Zsh completion as `v0.2.0`.
- Synchronize runtime, README, development, PRODUCT, ROADMAP, tests, and
  CHANGELOG metadata.
- Create and push an annotated `v0.2.0` tag and GitHub Release.
- Verify stable-channel selection and the published Release.
- Tests: 238 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; released.

### #012 Doctor — `src/doctor/doctor.zsh` (v0.2 per ROADMAP) — **closed**

- Target: `src/doctor/doctor.zsh`.
- Diagnose macOS, Zsh, Homebrew, the active MDTK executable, the managed shell
  hook, the offline command index, and writable MDTK user directories.
- Print one concise result per check followed by an actionable summary.
- Return zero only when every required check passes; warnings remain visible
  but do not fail the command.
- Support `mdtk doctor` and `mdtk doctor help`; reject unknown arguments.
- Never mutate the environment, install software, rebuild data, or use the
  network.
- Tests: success, required-check failure, warning, empty/default invocation,
  unknown/whitespace/Unicode input, large index, docs, CHANGELOG, DoD, review.
- Tests: 238 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; merged.

### #057 Native Zsh command completion — **closed**

- Target: Zsh shell integration (`completions/_mdtk`, `scripts/mdtk.zsh`).
- Complete top-level commands, module subcommands, and supported options.
- Register through `fpath`/`compdef` without running `compinit`.
- Never invoke MDTK, Homebrew, Git, or the network during completion.
- Preserve command-not-found behavior and idempotent shell-hook loading.
- Tests: command/option coverage, registration order, idempotency, no external
  calls, Unicode/whitespace input, performance, docs, CHANGELOG, DoD, review.
- Tests: 228 examples green in normal and `NO_COLOR=1` environments; real Zsh
  Tab flows verified; average completion 0.011 ms and hook registration 0.075
  ms; DoD met; reviewed.

### #056 Release version 0.1.5 — **closed**

- Published global colored output as annotated tag and GitHub Release
  `v0.1.5`; updated the managed stable installation successfully.
- Tests: 214 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed; released.

### #055 Colored-output documentation sync — **closed**

- Documented the global no-icon color policy and kept command data plain.
- Synchronized Logger, CNF, install, and shell-hook examples.
- Tests: 214 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #054 Homebrew backend colored errors — **closed**

- Missing-Homebrew backend errors use ERROR; package and install output remain
  unchanged.
- Tests: 214 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #053 Cache colored errors — **closed**

- Unknown cache subcommands use ERROR; values, lists, and paths remain plain.
- Tests: 214 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #052 Config colored errors — **closed**

- Unknown config subcommands use ERROR; values, lists, and paths remain plain.
- Tests: 213 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #051 Developer-installer colored presentation — **closed**

- The conda developer bootstrap uses aligned semantic colors while preserving
  dependency versions, isolation, stderr, and symlink behavior.
- Tests: 213 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

### #050 Dispatcher colored errors — **closed**

- Unknown commands and recovery guidance use ERROR/INFO; help, version, normal
  routing, stdout, and exit statuses remain unchanged.
- Tests: 210 examples green in normal and `NO_COLOR=1` environments; DoD met;
  reviewed.

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
