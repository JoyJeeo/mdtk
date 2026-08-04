# Vision

> The "why" behind MDTK. Who it is for, what it solves, and where it is going.

## The problem

macOS ships with a great terminal, but the developer experience of *using* it day-to-day still has friction:

- You type a command that is not installed. You get `command not found: rg` and stop. There is no search, no recommendation, no context.
- Homebrew is the de facto package manager, but discovering the right formula for a command, and remembering which formula provides it, is manual work.
- Developer environments drift. You forget what is installed, what is broken, what is stale. Diagnosing it is a chore of `brew doctor`, version checks, and `which`-chasing.
- Shell tooling is either heavyweight frameworks (oh-my-zsh, prezto) that own your whole shell, or scattered scripts with no discoverability.

The result: small, repeatable annoyances that compound across a day.

## The mission

**Provide the best terminal experience for macOS developers.**

MDTK is a focused, friendly, reliable toolkit that closes those gaps — without taking over your shell, without introducing magic, and without becoming another framework.

It does one job: make the everyday terminal smarter.

## Who it is for

- **Developers** — who want a command not found that actually helps.
- **AI engineers** — who live in the terminal between notebook sessions.
- **Linux users switching to macOS** — who miss the friendlier `command-not-found` experience from Debian/Ubuntu.
- **Students** — learning the shell, who benefit from guidance instead of dead-ends.
- **Heavy terminal users** — who want fast, cacheable, scriptable helpers.

## Design goals

| Goal     | What it means here                                                        |
| -------- | ------------------------------------------------------------------------- |
| Simple   | User-facing messages in plain language. No jargon. One clear next step.   |
| Fast     | Shell startup stays fast. Heavy work uses a cache, never the hot path.    |
| Friendly | Never a dead-end. Unknown command → search → recommendation → reason.      |
| Reliable | Tested, documented, no quick hacks. Behavior you can depend on.          |

## What MDTK is NOT

- Not a shell framework. It does not manage your prompt, plugins, or `~/.zshrc`.
- Not a replacement for Homebrew. It calls Homebrew as a backend.
- Not a kitchen sink. Features ship one at a time, only when they earn their place (see `.ai/ROADMAP.md`).

## Non-goals, stated explicitly

- We do not aim to support Linux or other Unices. macOS only.
- We do not aim to be a package manager. Search and recommend, then delegate.
- We do not aim to be the fastest possible shell tool at the cost of readability. Performance is bounded by "startup must stay fast"; beyond that, clarity wins.

## Success looks like

- A user types an uninstalled command and gets a one-line recommendation they can act on.
- A user runs `mdtk doctor` and immediately knows what is broken in their environment.
- A contributor opens `.ai/TASK.md`, implements one module, ships it, and the next person can pick up the next task — with no archaeology required.

## Where this is going

The roadmap lives in `.ai/ROADMAP.md`. In short:

- **Shipped in v0.1** — Logger, Config, Cache, Homebrew search,
  install recommendations, command index, and command-not-found integration.
- **Shipped in v0.2** — local environment diagnostics and native Zsh
  completion.
- **Shipped in v0.3** — explicit, lazy user plugin discovery and execution.
- **Next** — pip, cargo, conda, and npm backends, then the v1.0 release.
- **v0.4** — more package backends (pip, cargo, conda, npm).
- **v1.0** — production release.

Each version is small, testable, and independently useful. We are building toward v1.0 one milestone at a time.
