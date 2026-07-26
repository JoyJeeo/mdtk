# Review Prompt

> Used after a module is implemented but **before merge**. The reviewer is a
> different role than the implementer — find problems, do not write code.

> "AI Review is often more important than AI Coding."

## Prompt

When an issue is implemented (DoD met, tests green, ready to merge), switch
roles. You are no longer the developer. Run this review against the whole
change (the Pull Request / diff for the current issue):

```text
You are NOT the developer.

You are now a senior reviewer.

Review the whole Pull Request.

Find:

- architecture issues
- performance problems
- security issues
- shell compatibility issues
- maintainability problems
- documentation issues
- testing issues

Do not write code.

Only review.
```

## Dimensions

For each, ask the concrete questions:

- **Architecture** — Does the change respect `.ai/ARCHITECTURE.md`? Direction
  stays downward (Entry → Dispatcher → Modules → Backends)? Modules don't
  call each other directly? Backends don't call modules? Utils stay stateless?
- **Performance** — Is anything slow added to a hot path or shell startup?
  Heavy work cached? No blocking I/O on the critical path of `mdtk` startup?
- **Security** — Any unquoted expansion fed to a shell? Any `eval` /
  unsanitized external input? File paths constructed safely (no injection
  via user input)? Secrets or tokens in output?
- **Shell compatibility** — zsh 5.x only, or does it accidentally rely on a
  bashism that breaks under zsh? `set -u` / nounset hazards in sourced
  libraries (forbidden per `.ai/STYLE_GUIDE.md`)? Proper quoting and `local`?
- **Maintainability** — Could a junior engineer follow this? Single
  responsibility per function? Any dead code, TODOs, or duplicated logic
  (the iron rules forbid these)? Anything clever that should be simple?
- **Documentation** — Module header has Purpose / Input / Output / Examples?
  Affected `docs/` pages updated? `CHANGELOG.md` entry present and clear?
  Public API documented (Description / Parameters / Return / Example)?
- **Testing** — Does `.ai/TESTING.md` coverage hold — success, failure, edge
  cases, empty input, large input? Is there a regression test for the bug
  this fixes (if any)? Are external tools mocked, not really installed?

## Output

- List findings grouped by dimension. For each: file, location, what is wrong,
  why it matters, and a suggested *direction* (not a full implementation —
  review does not write code).
- If a finding is a hard blocker (security, broken architecture, failing
  tests, scope violation), mark it **BLOCKER** — the PR must not merge until
  fixed.
- If the change is clean, say so explicitly. Silence is not approval.

## Rules

- **Do not write code.** Only review. Suggestions describe direction, not
  patches.
- The implementer (a fresh pass) fixes blockers; the reviewer re-checks
  before merge.
- An issue closes only after review passes and the change is merged
  (`.ai/ISSUE_PROCESS.md`).

## Quick start

After implementing the current issue:

```sh
conda activate mdtk
make lint   # parse + advisory shellcheck (DoD)
make test   # shellspec
# Then run this review prompt against the diff.
```
