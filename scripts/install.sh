#!/usr/bin/env zsh
# ============================================================
# File:    scripts/install.sh
# Purpose: User-facing one-shot installer for MDTK.
# Author:  MDTK Team
# Date:    2026-07-27
# ============================================================
#
# Description
#   The checkout installer invoked by the top-level `install.sh`
#   bootstrap. It:
#     1. Refuses on non-macOS or non-zsh.
#     2. Detects Homebrew; if missing, prints the official install
#        command and exits (does NOT auto-run the network pipe).
#     3. Installs the `mdtk` command onto PATH (symlink into the first
#        writable, on-PATH dir among /usr/local/bin and ~/.local/bin).
#     4. Appends a `source <repo>/scripts/mdtk.zsh` line to ~/.zshrc
#        (idempotent — skips if already present; backs up first).
#     5. Runs an initial `mdtk index build`.
#     6. Prints a friendly finish message.
#
#   Usage (no conda env needed):
#       zsh install.sh
#   Remote bootstrap:
#       curl -fsSL https://raw.githubusercontent.com/JoyJeeo/mdtk/main/install.sh | zsh
#
# Parameters
#   none.
#
# Return
#   0  installed (or already installed).
#   1  prerequisites missing / IO failure.
# ============================================================

set -eu

# Shared stateless presentation utility from this checkout.
source "${${(%):-%x}:A:h:h}/src/utils/color.zsh"

# ------------------------------------------------------------
# _mdtk_install_say <kind> <msg>  — consistent colored status printer.
# ------------------------------------------------------------
_mdtk_install_say() {
    local kind="$1"
    local msg="$2"
    local level=""
    case "$kind" in
        info)    level="info" ;;
        success) level="success" ;;
        warn)    level="warning" ;;
        error)   mdtk_utils_color_log "error" "$msg" >&2; return $? ;;
        *)       return 1 ;;
    esac
    mdtk_utils_color_log "$level" "$msg"
}

# ------------------------------------------------------------
# _mdtk_install_error <msg>  — print + exit 1.
# ------------------------------------------------------------
_mdtk_install_error() {
    _mdtk_install_say error "$1"
    exit 1
}

# ------------------------------------------------------------
# _mdtk_install_resolve_repo
# ------------------------------------------------------------
# Description: resolve the MDTK repo root from this script's location.
#   When run via curl|sh, this script is in a temp dir with no repo —
#   in that case the user should clone first; we detect and error.
# Parameters: none. Return: 0; prints root path.
# ------------------------------------------------------------
_mdtk_install_resolve_repo() {
    local self
    self="${(%):-%x}"
    local here
    here="${self:A:h}"
    # If a sibling bin/mdtk exists, we are at <repo>/scripts.
    if [[ -x "${here:h}/bin/mdtk" ]]; then
        echo "${here:h}"
        return 0
    fi
    # Not run from a repo checkout.
    return 1
}

# ------------------------------------------------------------
# _mdtk_install_macos_check
# ------------------------------------------------------------
# Description: ensure we are on macOS. Return 0/1.
# ------------------------------------------------------------
_mdtk_install_macos_check() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# ------------------------------------------------------------
# _mdtk_install_zsh_check
# ------------------------------------------------------------
# Description: ensure zsh is the running shell. Return 0/1.
# ------------------------------------------------------------
_mdtk_install_zsh_check() {
    [[ -n "${ZSH_VERSION:-}" ]]
}

# ------------------------------------------------------------
# _mdtk_install_brew_check
# ------------------------------------------------------------
# Description: detect Homebrew; if missing, print the official
# install command and exit 1 (do NOT auto-run the network pipe).
# ------------------------------------------------------------
_mdtk_install_brew_check() {
    # Recognize either a real `brew` command on PATH, or a `brew`
    # shell function (the latter is how tests/curl-install can mock
    # brew without the real binary).
    if (( ${+functions[brew]} )); then
        return 0
    fi
    if (( ${+commands[brew]} )); then
        return 0
    fi
    _mdtk_install_say warn "Homebrew is not installed."
    _mdtk_install_say info "Install it first with:"
    _mdtk_install_say info '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    _mdtk_install_say info "Then re-run this installer."
    return 1
}

# ------------------------------------------------------------
# _mdtk_install_target_bin
# ------------------------------------------------------------
# Description: pick the first writable, on-PATH dir from a preferred
# list for the `mdtk` symlink. Prints the dir or nothing.
# ------------------------------------------------------------
_mdtk_install_target_bin() {
    local candidate entry on_path
    local preferred=()
    local brew_command="${commands[brew]:-}"
    if [[ -n "$brew_command" ]]; then
        preferred+=("${brew_command:A:h}")
    fi
    preferred+=("/usr/local/bin" "${HOME}/.local/bin")
    local seen=""
    for candidate in "${preferred[@]}"; do
        [[ ":${seen}:" == *":${candidate}:"* ]] && continue
        seen="${seen}:${candidate}"
        # On PATH?
        on_path=0
        for entry in ${(s/:/)PATH}; do
            if [[ "$entry" == "$candidate" ]]; then
                on_path=1
                break
            fi
        done
        (( on_path )) || continue
        # Prefer a candidate that already exists AND is writable.
        if [[ -d "$candidate" && -w "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
        # If it does not exist, try to create it.
        if [[ ! -e "$candidate" ]] && mkdir -p "$candidate" 2>/dev/null; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# ------------------------------------------------------------
# _mdtk_install_backup_zshrc <path>
# ------------------------------------------------------------
# Description: create a required timestamped backup before modification.
# Parameters: $1 zshrc path. Return: 0 backed up; 1 copy failed.
# Example: _mdtk_install_backup_zshrc "$HOME/.zshrc"
# ------------------------------------------------------------
_mdtk_install_backup_zshrc() {
    local zshrc="$1"
    local backup="${zshrc}.mdtk-backup.$(date +%s).$$"
    cp "$zshrc" "$backup" 2>/dev/null
}

# ------------------------------------------------------------
# _mdtk_install_zshrc_hook <repo>
# ------------------------------------------------------------
# Description: append the source line to ~/.zshrc (idempotent). Backs
# up first.
# Parameters: $1 repo root.
# ------------------------------------------------------------
_mdtk_install_zshrc_hook() {
    local repo="$1"
    local zshrc="${HOME}/.zshrc"
    local hook="source \"${repo}/scripts/mdtk.zsh\""
    # Exact hook already present? Skip.
    if [[ -f "$zshrc" ]] && grep -qxF "$hook" "$zshrc" 2>/dev/null; then
        _mdtk_install_say info "shell hook already in ${zshrc}; skipping."
        return 0
    fi
    # Migrate an older MDTK checkout hook to this checkout. Match only an
    # exact `source ".../scripts/mdtk.zsh"` line and preserve all others.
    if [[ -f "$zshrc" ]]; then
        local line has_old=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == source\ \"* && "$line" == */scripts/mdtk.zsh\" ]]; then
                has_old=1
                break
            fi
        done < "$zshrc"
        if (( has_old )); then
            _mdtk_install_backup_zshrc "$zshrc" || return 1
            local tmp="${zshrc}.mdtk-install.$$"
            local wrote_hook=0
            {
                while IFS= read -r line || [[ -n "$line" ]]; do
                    if [[ "$line" == source\ \"* && "$line" == */scripts/mdtk.zsh\" ]]; then
                        if (( ! wrote_hook )); then
                            echo "$hook"
                            wrote_hook=1
                        fi
                    else
                        echo "$line"
                    fi
                done < "$zshrc"
            } > "$tmp" || { rm -f "$tmp"; return 1; }
            mv -f "$tmp" "$zshrc" || { rm -f "$tmp"; return 1; }
            _mdtk_install_say success "shell hook updated in ${zshrc}."
            return 0
        fi
    fi
    # Back up.
    if [[ -f "$zshrc" ]]; then
        _mdtk_install_backup_zshrc "$zshrc" || return 1
    fi
    {
        echo ""
        echo "# Added by mdtk installer."
        echo "$hook"
    } >> "$zshrc"
    _mdtk_install_say success "shell hook added to ${zshrc}."
}

# ------------------------------------------------------------
# _mdtk_install_link_cmd <repo> <bindir>
# ------------------------------------------------------------
# Description: symlink bin/mdtk into <bindir>/mdtk (idempotent).
# ------------------------------------------------------------
_mdtk_install_link_cmd() {
    local repo="$1"
    local bindir="$2"
    local target="${repo}/bin/mdtk"
    local link="${bindir}/mdtk"
    if [[ -L "$link" || -e "$link" ]]; then
        rm -f "$link"
    fi
    ln -s "$target" "$link"
    _mdtk_install_say success "linked 'mdtk' -> ${link}"
}

# ============================================================
# main
# ============================================================

# 1. macOS + zsh
if ! _mdtk_install_macos_check; then
    _mdtk_install_error "MDTK is macOS-only (got: $(uname -s))."
fi
if ! _mdtk_install_zsh_check; then
    _mdtk_install_error "MDTK must be run under zsh (re-run with: zsh install.sh)."
fi

# 2. Repo root (must run from a checkout).
repo=""
if ! repo="$(_mdtk_install_resolve_repo)"; then
    _mdtk_install_error "Could not find the MDTK repo. Clone it first:
  git clone https://github.com/JoyJeeo/mdtk.git
  cd mdtk
  zsh install.sh"
fi
_mdtk_install_say info "repo: ${repo}"

# 3. Homebrew
if ! _mdtk_install_brew_check; then
    exit 1
fi
_mdtk_install_say success "Homebrew detected."

# 4. Install `mdtk` command onto PATH.
bindir=""
if ! bindir="$(_mdtk_install_target_bin)"; then
    _mdtk_install_error "No writable, on-PATH bin dir found. Try:
  mkdir -p ~/.local/bin && ensure it is on PATH, then re-run."
fi
_mdtk_install_link_cmd "$repo" "$bindir"

# 5. Shell hook in ~/.zshrc.
_mdtk_install_zshrc_hook "$repo"

# 6. Initial index build.
_mdtk_install_say info "building command index (mdtk index build)..."
if mdtk index build 2>/dev/null; then
    _mdtk_install_say success "command index built."
else
    _mdtk_install_say warn "index build skipped (brew may have been busy). Run 'mdtk index build' later."
fi

# 7. Finish.
echo ""
_mdtk_install_say success "MDTK installed. Restart your shell (or run: source ~/.zshrc), then try:"
_mdtk_install_say info "  mdtk version"
_mdtk_install_say info "  rg some-file   # (if rg is not installed, you'll get a recommendation)"
