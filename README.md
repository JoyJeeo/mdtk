# mdtk

**Mac Developer Toolkit (MDTK)** — a developer toolkit for macOS, written in zsh.

Better terminal experience for developers, AI engineers, Linux-to-macOS switchers, students, and heavy terminal users.

> **Status:** v0.1.0 released. The toolkit provides structured logging, config, a cache, a Homebrew backend, package search, install recommendations, a command→formula index, and a smart command-not-found handler wired into zsh. See `.ai/ROADMAP.md` for what's next (Doctor, Plugin, more backends).

The headline feature: type an uninstalled command and MDTK tells you which Homebrew formula provides it and how to install it.

```
$ rg file
Found: the "rg" command is provided by the "ripgrep" formula.
Run: brew install ripgrep
```

---

## Requirements

- **macOS** (Apple Silicon or Intel)
- **zsh** 5.x (the default shell on macOS)
- **[Homebrew](https://brew.sh)** (for the search / install / command-not-found features)

> No conda/Python needed for everyday use. Conda is only used by **developers** of MDTK for the test tooling (see [For developers](#for-developers)).

---

## Install (end users)

Run the one-shot installer:

```sh
git clone https://github.com/JoyJeeo/mdtk.git
cd mdtk
zsh scripts/install.sh
```

The installer will:

1. **Verify the environment** — refuses on non-macOS or non-zsh.
2. **Check Homebrew** — if missing, prints the official Homebrew install command and exits (it does **not** auto-run the network pipe). Install Homebrew, then re-run.
3. **Install the `mdtk` command** — symlinks `bin/mdtk` onto the first writable, on-PATH directory among `/usr/local/bin` and `~/.local/bin`.
4. **Wire the shell hook** — appends `source <repo>/scripts/mdtk.zsh` to `~/.zshrc` (idempotent — skipped if already present; backs up `~/.zshrc` first).
5. **Build the command index** — runs `mdtk index build` (skipped with a warning if brew is busy).
6. Print a friendly finish message.

Then **restart your shell** (or run `exec zsh`):

```sh
exec zsh
which mdtk        # -> /usr/local/bin/mdtk  or  ~/.local/bin/mdtk
mdtk version      # -> mdtk 0.1.0
```

> If `which mdtk` is empty after restart, your `~/.zshrc`/`~/.zprofile` does not put `~/.local/bin` on PATH. Add `export PATH="$HOME/.local/bin:$PATH"` to `~/.zshrc` and `exec zsh` again.

### One-time setup of the index

The installer builds it, but you should rebuild it after installing new formulae so recommendations stay accurate:

```sh
mdtk index build
```

---

## Usage

### Smart command-not-found (the headline feature)

Once the shell hook is sourced (the installer does this), typing an uninstalled command gives you a recommendation instead of a bare "command not found":

```sh
$ rg file
Found: the "rg" command is provided by the "ripgrep" formula.
Run: brew install ripgrep

$ nonexistent_cmd_xyz
No Homebrew formula found that provides "nonexistent_cmd_xyz".
Try: mdtk search nonexistent_cmd_xyz
```

You can also trigger it manually:

```sh
mdtk cnf rg
```

### Command reference

| Command | What it does |
| --- | --- |
| `mdtk version` | Show the installed version. |
| `mdtk help` | List available commands. |
| `mdtk index build` | Build the command→formula index from Homebrew (rebuild after installing new formulae). |
| `mdtk index lookup <cmd>` | Look up which formula provides a command (exit 1 if absent). |
| `mdtk index path` | Print the index file path. |
| `mdtk search <query>` | Search Homebrew formulae; prints matches one per line. |
| `mdtk install <command>` | Find the formula that provides a command and print a recommendation (does **not** auto-install in v0.1). |
| `mdtk cnf <command>` | The command-not-found handler (usually called automatically by the shell hook). |
| `mdtk config get/set/list/path` | Read/write user configuration. |
| `mdtk cache get/set/clean/list/path` | Manage the on-disk cache. |
| `mdtk logger --<level> "msg"` | Structured logging (INFO/SUCCESS/WARNING/ERROR/DEBUG). |

### Logger

```sh
mdtk logger --info "starting up"        # [INFO] starting up
mdtk logger --success "done"            # [SUCCESS] done
mdtk logger --warning "slow"            # [WARNING] slow
mdtk logger --error "failed"            # [ERROR] failed
mdtk logger --debug "x=42"             # (silent unless debug mode is on)
```

Modes: colors on by default · `NO_COLOR=1` or `--no-color` to disable · `--quiet` (ERROR only) · `--debug` or `MDTK_DEBUG=1` to show DEBUG.

```sh
NO_COLOR=1 mdtk logger --quiet --error "boom"    # only errors, no color
MDTK_DEBUG=1 mdtk logger --debug "x=42"          # debug output
```

### Config

User preferences live at `~/.config/mdtk/config` (XDG-aware) as `key=value` lines:

```sh
mdtk config set color on
mdtk config get color          # -> on  (exit 1 if absent)
mdtk config list
mdtk config path
```

### Cache

The cache lives at `~/.cache/mdtk/` (XDG-aware). The command index is one such cache file:

```sh
mdtk cache set snapshot "data"
mdtk cache get snapshot
mdtk cache list
mdtk cache clean               # clear all
mdtk cache clean snapshot      # clear one
mdtk cache path
```

### Where files live (XDG-aware)

| What | Default path | Set via |
| --- | --- | --- |
| Config (user prefs) | `~/.config/mdtk/config` | `XDG_CONFIG_HOME` |
| Cache (incl. command index) | `~/.cache/mdtk/` | `XDG_CACHE_HOME` |
| Shell hook | appended to `~/.zshrc` by the installer | — |

---

## Uninstall

```sh
# 1. Remove the mdtk command from PATH
rm -f /usr/local/bin/mdtk ~/.local/bin/mdtk

# 2. Remove the shell hook line from ~/.zshrc
#    (the installer backs up ~/.zshrc first; restore from the .mdtk-backup.* copy,
#     or delete the two lines it added: the comment + the `source .../scripts/mdtk.zsh`)

# 3. Remove MDTK data (optional)
rm -rf ~/.cache/mdtk ~/.config/mdtk

# 4. Remove the repo clone (optional)
rm -rf /path/to/mdtk
```

Then `exec zsh` (or restart your terminal).

---

## For developers

Developers use a separate bootstrap (`install.zsh`) that installs the **test tooling** (shellspec + shellcheck) into a conda env named `mdtk`, and symlinks the `mdtk` command into the env's bin (so it's only active while the env is active).

```sh
git clone https://github.com/JoyJeeo/mdtk.git
cd mdtk
conda activate mdtk          # the conda env must already exist
./install.zsh                # installs shellspec + shellcheck + symlinks mdtk

make test                    # run the shellspec suite (98 examples)
make lint                    # zsh -n (hard parse gate) + shellcheck (advisory)
make smoke                   # sanity-check the CLI
```

### Layout

```
bin/mdtk              entry point
src/dispatcher.zsh    command dispatcher (infrastructure)
src/version.zsh       version constant
src/<module>/         one dir per module (logger/, config/, cache/, search/, install/, cnf/, ...)
src/core/             project-level read-only constants
src/utils/            stateless shared helpers (color, path, shell)
src/backends/         package-manager wrappers (homebrew, pip, ...)
tests/                shellspec tests
scripts/              user-facing installer (install.sh) + shell hook (mdtk.zsh)
docs/                 human-facing docs (vision, faq, architecture, development)
.ai/                  project specifications (read these first)
AGENTS.md             instructions for AI coding agents
```

### Documentation

- **`docs/vision.md`** — the why behind MDTK.
- **`docs/architecture.md`** — how the pieces fit (narrative).
- **`docs/development.md`** — how to build, test, and contribute.
- **`docs/faq.md`** — common questions.
- **`.ai/`** — the authoritative spec (read before coding).
- **`CHANGELOG.md`** — what changed and why.

### For AI coding agents

Read `AGENTS.md` and the `.ai/` specs **before** writing any code. Never implement outside the current task in `.ai/TASK.md`.

---

## License

MIT — see [LICENSE](LICENSE).
