#!/usr/bin/env zsh
# ============================================================
# File:    scripts/dev-install.zsh
# Purpose: Set up the MDTK development environment (test tooling).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   One-shot bootstrap for contributors:
#     1. Make sure the 'mdtk' conda env is active.
#     2. Install shellspec into that env (if missing).
#     3. Install shellcheck into that env (if missing).
#     4. Symlink bin/mdtk onto $CONDA_PREFIX/bin/mdtk.
#
#   Run inside the project root:
#       conda activate mdtk
#       ./install.zsh
#
# Parameters
#   None.
#
# Return
#   0  everything ready (or already ready).
#   1  wrong env, or a step failed.
# ============================================================

set -eu

# Shared stateless presentation utility from this checkout.
source "${0:A:h:h}/src/utils/color.zsh"

# Description: Print one developer-install status line.
# Parameters: $1 level; $2 message; $3 optional destination (`stderr`).
# Return: 0 printed; 1 invalid level.
# Example: _mdtk_dev_install_say "info" "Checking shellspec."
_mdtk_dev_install_say() {
    local level="$1"
    local message="$2"
    local destination="${3:-stdout}"
    if [[ "$destination" == "stderr" ]]; then
        mdtk_utils_color_log "$level" "$message" >&2
    else
        mdtk_utils_color_log "$level" "$message"
    fi
}

# ------------------------------------------------------------
# _mdtk_install_error  - print a friendly one-line error and exit.
# ------------------------------------------------------------
# Parameters: $1 message
# Return: never returns (exit 1)
# ------------------------------------------------------------
_mdtk_install_error() {
    local msg="$1"
    _mdtk_dev_install_say "error" "$msg" "stderr"
    _mdtk_dev_install_say "info" "Fix: make sure you ran 'conda activate mdtk' first." "stderr"
    exit 1
}

# 1. Env check ------------------------------------------------
if [[ "${CONDA_DEFAULT_ENV:-}" != "mdtk" ]]; then
    _mdtk_install_error "Not in the 'mdtk' conda env (got: '${CONDA_DEFAULT_ENV:-none}')."
fi

if [[ -z "${CONDA_PREFIX:-}" ]]; then
    _mdtk_install_error "CONDA_PREFIX is empty."
fi

local root_dir
# This script lives at <repo>/scripts/dev-install.zsh; root is one level up.
root_dir="${0:A:h:h}"

_mdtk_dev_install_say "info" "Conda env:    ${CONDA_DEFAULT_ENV}"
_mdtk_dev_install_say "info" "Env prefix:   ${CONDA_PREFIX}"
_mdtk_dev_install_say "info" "Project root: ${root_dir}"

# 2. shellspec ------------------------------------------------
local shellspec_bin="${CONDA_PREFIX}/bin/shellspec"

if [[ -x "$shellspec_bin" ]]; then
    _mdtk_dev_install_say "success" "shellspec already installed at ${shellspec_bin}"
else
    _mdtk_dev_install_say "info" "shellspec not found. Installing into the env..."
    local shellspec_version="0.28.1"
    local tmp_clone
    tmp_clone="$(mktemp -d)/shellspec"
    # Clone the pinned release tag, then `make install` into the env prefix
    # so shellspec only exists when 'mdtk' is active. No curl|sh.
    if git clone --branch "${shellspec_version}" --depth 1 \
            "https://github.com/shellspec/shellspec.git" "$tmp_clone"; then
        if make -C "$tmp_clone" install PREFIX="${CONDA_PREFIX}"; then
            _mdtk_dev_install_say "success" "shellspec ${shellspec_version} installed."
        else
            rm -rf "$tmp_clone"
            _mdtk_install_error "make install failed. Try manually:
  git clone --branch ${shellspec_version} https://github.com/shellspec/shellspec.git
  make -C shellspec install PREFIX=\"${CONDA_PREFIX}\""
        fi
        rm -rf "$tmp_clone"
    else
        rm -rf "$tmp_clone"
        _mdtk_install_error "git clone shellspec failed (version ${shellspec_version})."
    fi
fi

# 3. shellcheck ----------------------------------------------
local shellcheck_bin="${CONDA_PREFIX}/bin/shellcheck"

if [[ -x "$shellcheck_bin" ]]; then
    _mdtk_dev_install_say "success" "shellcheck already installed at ${shellcheck_bin}"
else
    _mdtk_dev_install_say "info" "shellcheck not found. Installing into the env..."
    # The ShellCheck executable is a conda-forge package, so installation
    # through conda works cleanly.
    if conda install -y -c conda-forge -n mdtk "shellcheck=0.11.0"; then
        _mdtk_dev_install_say "success" "shellcheck installed."
    else
        _mdtk_dev_install_say "warning" "shellcheck install failed (linting optional for now)." "stderr"
        _mdtk_dev_install_say "info" "Fix: conda install -c conda-forge -n mdtk shellcheck" "stderr"
    fi
fi

# 4. Symlink bin/mdtk ----------------------------------------
local mdtk_target="${root_dir}/bin/mdtk"
local mdtk_link="${CONDA_PREFIX}/bin/mdtk"

if [[ ! -x "$mdtk_target" ]]; then
    _mdtk_install_error "bin/mdtk not found or not executable at ${mdtk_target}"
fi

# Refresh link (idempotent).
if [[ -L "$mdtk_link" || -e "$mdtk_link" ]]; then
    rm -f "$mdtk_link"
fi
ln -s "$mdtk_target" "$mdtk_link"
_mdtk_dev_install_say "success" "Linked 'mdtk' -> ${mdtk_link}"

# Done -------------------------------------------------------
echo ""
_mdtk_dev_install_say "success" "All set. Try:"
echo "  mdtk version"
echo "  mdtk help"
echo "  make test"
