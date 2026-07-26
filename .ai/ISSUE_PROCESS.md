# Issue Process

> How work flows through MDTK: one issue at a time, one module per issue.

## The model

Work is tracked as **issues**, not as a single rolling `TASK.md`. Each feature
is its own issue. An issue is opened, implemented, reviewed, and closed before
the next one starts.

```
Issue #001  Logger
Issue #002  Config
Issue #003  Cache
Issue #004  Search
...
```

> The backlog lives in `.ai/TASK.md` as a numbered issue list. `.ai/TASK.md`
> no longer names a single ad-hoc task; it points at the current open issue
> and the queue behind it.

## One issue = one module = one feature

- An issue targets exactly **one module** (or one backend, or one util).
- An issue is **opened** before code is written and **closed** after review +
  merge.
- **Never work two issues at once.** Open issue #002 only after #001 is closed.

## Lifecycle of an issue

1. **Open** — add the issue to the top of the backlog in `.ai/TASK.md` (or mark
   the next queued issue as "current"). State the target module and a brief
   acceptance checklist.
2. **Implement** — replace the module's stub in `src/<module>/<module>.zsh`.
   Do not touch any other module (`.ai/DEVELOPMENT_RULES.md`).
3. **Test** — write specs under `tests/` (success / failure / edge / empty /
   large per `.ai/TESTING.md`).
4. **Document** — module header (Purpose / Input / Output / Examples) and any
   affected `docs/` page.
5. **Changelog** — add an `[Unreleased]` entry in `CHANGELOG.md`.
6. **Review** — run the review pass (`.ai/REVIEW_PROMPT.md` in a later phase,
   or a senior pass). Do not merge unreviewed.
7. **Close** — once merged, mark the issue closed in `.ai/TASK.md` and open the
   next one.

## Conventions

- Issue IDs are zero-padded three-digit: `#001`, `#002`, …
- IDs are never reused.
- The issue's target module must already exist as a stub in `src/<module>/`
  (phase 3 ensured this for all v0.1 modules).
- An issue is "current" when it is the top open item in `.ai/TASK.md`.

## Relationship to the roadmap

Issues are sourced from `.ai/ROADMAP.md`. The roadmap says *what ships in
each version*; the issue queue says *in what order we build the pieces of that
version*. One issue per roadmap line item, in roadmap order.
