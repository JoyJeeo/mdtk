#!/usr/bin/env zsh
# ============================================================
# File:    install.sh
# Purpose: Friendly local and remote bootstrap installer for MDTK.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   When run from a repository checkout, delegates to scripts/install.sh.
#   When read from stdin (for example via curl | zsh), clones MDTK into
#   the XDG data directory, marks it as managed, and runs that checkout's
#   installer. Existing unmarked directories are never overwritten.
#
# Parameters
#   None. Optional environment overrides:
#   MDTK_INSTALL_REPOSITORY_URL  Git repository URL.
#   MDTK_INSTALL_REF             Git branch or tag (default: main).
#   MDTK_INSTALL_BRANCH          Deprecated branch-only compatibility alias.
#
# Return
#   0  installation completed.
#   1  unsupported system, missing prerequisite, unsafe target, or failure.
#
# Example
#   zsh install.sh
#   curl -fsSL https://raw.githubusercontent.com/JoyJeeo/mdtk/main/install.sh | zsh
#   curl -fsSL https://raw.githubusercontent.com/JoyJeeo/mdtk/main/install.sh |
#       MDTK_INSTALL_REF=v0.1.1 zsh
# ============================================================

set -eu
set -o pipefail

typeset -r MDTK_BOOTSTRAP_MARKER_CONTENT="managed-by=mdtk-bootstrap-v1"
typeset -r MDTK_BOOTSTRAP_REPOSITORY_URL_DEFAULT="https://github.com/JoyJeeo/mdtk.git"
typeset -r MDTK_BOOTSTRAP_REF_FILE=".mdtk-managed-ref"

# Description: Print one friendly bootstrap status line.
# Parameters: $1 level, $2 message. Return: 0.
# Example: _mdtk_bootstrap_say "INFO" "Preparing MDTK."
_mdtk_bootstrap_say() {
    local level="$1"
    local message="$2"
    printf '[%s] %s\n' "$level" "$message"
}

# Description: Print an error and exit.
# Parameters: $1 message. Return: never returns.
# Example: _mdtk_bootstrap_fail "Git is required."
_mdtk_bootstrap_fail() {
    _mdtk_bootstrap_say "ERROR" "$1" >&2
    exit 1
}

# Description: Detect a real root-level script in a local checkout.
# Parameters: none. Return: 0 local checkout; 1 stdin/remote mode.
# Example: _mdtk_bootstrap_local_root
_mdtk_bootstrap_local_root() {
    local self
    self="${(%):-%x}"
    [[ "${self:t}" == "install.sh" ]] || return 1
    local here="${self:A:h}"
    [[ -f "${here}/scripts/install.sh" && -x "${here}/bin/mdtk" ]] || return 1
    echo "$here"
}

# Description: Resolve the XDG-aware managed install root.
# Parameters: none. Return: 0; prints an absolute path.
# Example: _mdtk_bootstrap_install_root
_mdtk_bootstrap_install_root() {
    local base="${XDG_DATA_HOME:-${HOME:-/tmp}/.local/share}"
    echo "${base:A}/mdtk"
}

# Description: Validate the managed install destination.
# Parameters: $1 target. Return: 0 safe; 1 unsafe.
# Example: _mdtk_bootstrap_safe_target "$target"
_mdtk_bootstrap_safe_target() {
    local target="$1"
    local parent="${target:h}"
    [[ -n "$target" && "${target:t}" == "mdtk" ]] || return 1
    [[ "$target" != "/" && "$target" != "${HOME:-}" ]] || return 1
    [[ "$parent" != "/" && "$parent" != "${HOME:-}" ]] || return 1
    return 0
}

# Description: Validate an existing managed checkout marker and files.
# Parameters: $1 target. Return: 0 managed; 1 unsafe/unmanaged.
# Example: _mdtk_bootstrap_existing_managed "$target"
_mdtk_bootstrap_existing_managed() {
    local target="$1"
    local marker="${target}/.mdtk-managed-install"
    [[ -d "$target" && -f "$marker" ]] || return 1
    [[ "$(<"$marker")" == "$MDTK_BOOTSTRAP_MARKER_CONTENT" ]] || return 1
    [[ -d "${target}/.git" && -f "${target}/scripts/install.sh" ]] || return 1
    return 0
}

# Description: Validate a branch/tag ref before passing it to Git.
# Parameters: $1 ref. Return: 0 safe; 1 invalid or option-like.
# Example: _mdtk_bootstrap_ref_is_safe "v0.1.1"
_mdtk_bootstrap_ref_is_safe() {
    local ref="$1"
    [[ -n "$ref" && ${#ref} -le 255 ]] || return 1
    case "$ref" in
        -*|*[^A-Za-z0-9._/-]*|*..*|*//*|*/.|.*|*/|*.lock) return 1 ;;
    esac
    return 0
}

# Description: Fetch and check out the exact requested ref in a managed tree.
# Parameters: $1 checkout, $2 ref. Return: 0 success; 1 Git/metadata failure.
# Example: _mdtk_bootstrap_checkout_ref "$root" "v0.1.1"
_mdtk_bootstrap_checkout_ref() {
    local checkout="$1"
    local ref="$2"
    git -C "$checkout" fetch --depth 1 origin "$ref" || return 1
    git -C "$checkout" checkout --detach FETCH_HEAD || return 1
    return 0
}

# Description: Execute local delegation or the managed remote install flow.
# Parameters: none. Return: 0 success; exits 1 through the failure helper.
# Example: _mdtk_bootstrap_main
_mdtk_bootstrap_main() {
    local local_root=""
    if [[ "${MDTK_BOOTSTRAP_MANAGED_MODE:-0}" != "1" ]] && \
        local_root="$(_mdtk_bootstrap_local_root)"; then
        _mdtk_bootstrap_say "INFO" "Installing from local checkout: ${local_root}"
        zsh "${local_root}/scripts/install.sh"
        return $?
    fi

    [[ "$(uname -s)" == "Darwin" ]] || _mdtk_bootstrap_fail "MDTK supports macOS only."
    command -v git >/dev/null 2>&1 || _mdtk_bootstrap_fail "Git is required. Install Git, then try again."

    local repository_url="${MDTK_INSTALL_REPOSITORY_URL:-$MDTK_BOOTSTRAP_REPOSITORY_URL_DEFAULT}"
    local ref="${MDTK_INSTALL_REF:-${MDTK_INSTALL_BRANCH:-main}}"
    [[ -n "$repository_url" ]] || _mdtk_bootstrap_fail "Repository URL must not be empty."
    _mdtk_bootstrap_ref_is_safe "$ref" || _mdtk_bootstrap_fail "Invalid install ref: ${ref}"

    local install_root
    install_root="$(_mdtk_bootstrap_install_root)"
    _mdtk_bootstrap_safe_target "$install_root" || _mdtk_bootstrap_fail "Refusing unsafe install path: ${install_root}"

    local existing_install=0 previous_head="" previous_ref="" had_previous_ref=0
    if [[ -e "$install_root" ]]; then
        existing_install=1
        _mdtk_bootstrap_existing_managed "$install_root" || \
            _mdtk_bootstrap_fail "Install path already exists and is not managed by MDTK: ${install_root}"
        previous_head="$(git -C "$install_root" rev-parse HEAD)" || \
            _mdtk_bootstrap_fail "Could not record the current managed checkout revision."
        if [[ -f "${install_root}/${MDTK_BOOTSTRAP_REF_FILE}" ]]; then
            previous_ref="$(<"${install_root}/${MDTK_BOOTSTRAP_REF_FILE}")"
            had_previous_ref=1
        fi
        local existing_url
        existing_url="$(git -C "$install_root" remote get-url origin)" || \
            _mdtk_bootstrap_fail "Could not verify the managed checkout origin."
        [[ "$existing_url" == "$repository_url" ]] || \
            _mdtk_bootstrap_fail "Managed checkout origin does not match this installer."
        _mdtk_bootstrap_say "INFO" "Installing ref ${ref} in managed checkout: ${install_root}"
        _mdtk_bootstrap_checkout_ref "$install_root" "$ref" || \
            _mdtk_bootstrap_fail "Could not install ref: ${ref}"
    else
        local install_parent="${install_root:h}"
        mkdir -p "$install_parent" || _mdtk_bootstrap_fail "Could not create: ${install_parent}"
        local tmp_dir
        tmp_dir="$(mktemp -d "${install_parent}/.mdtk-install.XXXXXX")" || \
            _mdtk_bootstrap_fail "Could not create a temporary install directory."

        # Description: Remove this run's mktemp-created staging directory.
        # Parameters: none. Return: 0.
        # Example: _mdtk_bootstrap_cleanup
        _mdtk_bootstrap_cleanup() {
            [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]] && rm -rf -- "$tmp_dir"
        }
        trap _mdtk_bootstrap_cleanup EXIT HUP INT TERM

        local checkout="${tmp_dir}/repo"
        _mdtk_bootstrap_say "INFO" "Downloading MDTK."
        git clone --depth 1 --branch "$ref" -- "$repository_url" "$checkout" || \
            _mdtk_bootstrap_fail "Could not download MDTK."
        [[ -x "${checkout}/bin/mdtk" && -f "${checkout}/scripts/install.sh" ]] || \
            _mdtk_bootstrap_fail "Downloaded checkout is incomplete."
        echo "$MDTK_BOOTSTRAP_MARKER_CONTENT" > "${checkout}/.mdtk-managed-install" || \
            _mdtk_bootstrap_fail "Could not mark the managed checkout."
        mv "$checkout" "$install_root" || _mdtk_bootstrap_fail "Could not activate the managed checkout."
        rmdir "$tmp_dir"
        tmp_dir=""
        trap - EXIT HUP INT TERM
    fi

    _mdtk_bootstrap_say "INFO" "Running the MDTK installer."
    if ! zsh "${install_root}/scripts/install.sh"; then
        if (( existing_install )); then
            _mdtk_bootstrap_say "WARNING" "Target setup failed; restoring the previous installation."
            git -C "$install_root" checkout --detach "$previous_head" || \
                _mdtk_bootstrap_fail "Target setup failed and the previous checkout could not be restored."
            if (( had_previous_ref )); then
                echo "$previous_ref" > "${install_root}/${MDTK_BOOTSTRAP_REF_FILE}" || \
                    _mdtk_bootstrap_fail "Target setup failed and previous ref metadata could not be restored."
            else
                rm -f -- "${install_root}/${MDTK_BOOTSTRAP_REF_FILE}"
            fi
            zsh "${install_root}/scripts/install.sh" || \
                _mdtk_bootstrap_fail "Target setup failed; the previous checkout was restored but setup also failed."
            _mdtk_bootstrap_fail "Could not install ref: ${ref}; the previous installation was restored."
        fi
        _mdtk_bootstrap_existing_managed "$install_root" && rm -rf -- "$install_root"
        _mdtk_bootstrap_fail "MDTK setup did not complete; the incomplete installation was removed."
    fi
    if ! echo "$ref" > "${install_root}/${MDTK_BOOTSTRAP_REF_FILE}"; then
        if (( existing_install )); then
            _mdtk_bootstrap_say "WARNING" "Ref metadata failed; restoring the previous installation."
            git -C "$install_root" checkout --detach "$previous_head" || \
                _mdtk_bootstrap_fail "Ref metadata failed and the previous checkout could not be restored."
            if (( had_previous_ref )); then
                echo "$previous_ref" > "${install_root}/${MDTK_BOOTSTRAP_REF_FILE}" || \
                    _mdtk_bootstrap_fail "Ref metadata failed and previous metadata could not be restored."
            else
                rm -f -- "${install_root}/${MDTK_BOOTSTRAP_REF_FILE}"
            fi
            zsh "${install_root}/scripts/install.sh" || \
                _mdtk_bootstrap_fail "Ref metadata failed; the previous checkout was restored but setup also failed."
            _mdtk_bootstrap_fail "Could not record ref ${ref}; the previous installation was restored."
        fi
        _mdtk_bootstrap_existing_managed "$install_root" && rm -rf -- "$install_root"
        _mdtk_bootstrap_fail "Could not record the managed install ref; the incomplete installation was removed."
    fi
    _mdtk_bootstrap_say "SUCCESS" "MDTK is ready."
    return 0
}

_mdtk_bootstrap_main "$@"
