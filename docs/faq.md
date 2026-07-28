# FAQ

Frequently asked questions. Short answers, with a pointer to where you can learn more.

---

## What is MDTK?

MDTK (Mac Developer Toolkit) is a developer toolkit for macOS, written in zsh. It makes everyday terminal tasks friendlier: a smart `command not found`, package search, install recommendations, environment diagnostics, and more.

See [Vision](vision.md).

## Is it a shell framework like oh-my-zsh?

No. MDTK does not manage your prompt, your plugins, or your `~/.zshrc`. It is a single `mdtk` command you call when you need it. It plays nicely with whatever shell setup you already have.

## What do I need to run it?

- macOS (Apple Silicon or Intel)
- zsh (the default shell on macOS)
- Homebrew for package search, recommendations, and command-not-found lookup

End users do not need conda. Contributors use an `mdtk` conda environment
only for ShellSpec and ShellCheck. See the [installation guide](../README.md#安装普通用户).

## How do I install it?

End users run the remote bootstrap (no conda or manual clone needed):

```sh
curl -fsSL https://raw.githubusercontent.com/JoyJeeo/mdtk/main/install.sh | zsh
exec zsh
```

To inspect it first, download the same top-level `install.sh`, review it,
then run `zsh install.sh`.

Developers (who want to run tests) use a separate bootstrap that
sets up the test tooling inside a conda env:

```sh
conda activate mdtk
./scripts/dev-install.zsh
```

## How do I update it?

MDTK is installed from source. Pull the latest and you are done:

```sh
git pull
mdtk version
```

If the test framework needs to change, re-run `./scripts/dev-install.zsh` (it is idempotent).

## I typed `mdtk doctor` or `mdtk plugin` and it said "not implemented yet". Why?

Those two modules are still stubs. Logger, Config, Cache, Homebrew Search,
Install recommendation, Command Index, and command-not-found support are
implemented. New features ship one issue at a time; see `.ai/TASK.md` and
`.ai/ISSUE_PROCESS.md`.

## I got "Unknown command". What now?

Run `mdtk help` for the list of available commands. Commands that are not yet implemented are clearly marked.

## Can I use it on Linux?

No. MDTK targets macOS. The package backends (Homebrew, etc.) and the developer-experience goals are macOS-specific. Supporting other platforms is a non-goal.

## Does MDTK replace Homebrew?

No. Homebrew remains the package manager. MDTK *calls* Homebrew as a backend to search and recommend, then hands the actual install back to `brew`.

## Why zsh and not bash / Python / Go?

- **zsh** is the default shell on macOS, so MDTK runs where its users already are, with no runtime install for the core tooling.
- The shell is the natural home for a `command not found` / package-search tool.
- Keeping it in shell keeps startup fast and the dependency surface small.

The test framework (`shellspec`) is also shell-native and runs under zsh.

## How do I run the tests?

```sh
conda activate mdtk
make test
```

This runs the `shellspec` suite. See [Development](development.md).

## How do I contribute?

Read [Development](development.md) and `AGENTS.md` first, then the `.ai/` specs. The short version: one task at a time, one feature per commit, tests + docs + examples required, never modify unrelated modules.

## Where does the name come from?

**M**ac **D**eveloper **T**ool**k**it. Short name: `mdtk`.

## Where do I report bugs / request features?

Open an issue on the GitHub repository. Each feature is tracked through the roadmap and the workflow in `.ai/ISSUE_PROCESS.md`.

## I'm an AI coding agent. Where do I start?

Read `AGENTS.md` at the repository root. It tells you to read every file under `.ai/` before doing anything, and to implement only the current open issue in `.ai/TASK.md` (one issue at a time — see `.ai/ISSUE_PROCESS.md`).
