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

# ------------------------------------------------------------
# _mdtk_install_error  - print a friendly one-line error and exit.
# ------------------------------------------------------------
# Parameters: $1 message
# Return: never returns (exit 1)
# ------------------------------------------------------------
_mdtk_install_error() {
    local msg="$1"
    echo "ERROR: ${msg}" >&2
    echo "Fix: make sure you ran 'conda activate mdtk' first." >&2
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

echo "INFO  Conda env:    ${CONDA_DEFAULT_ENV}"
echo "INFO  Env prefix:   ${CONDA_PREFIX}"
echo "INFO  Project root: ${root_dir}"

# 2. shellspec ------------------------------------------------
local shellspec_bin="${CONDA_PREFIX}/bin/shellspec"

if [[ -x "$shellspec_bin" ]]; then
    echo "SUCCESS shellspec already installed at ${shellspec_bin}"
else
    echo "INFO  shellspec not found. Installing into the env..."
    local shellspec_version="0.28.1"
    local tmp_clone
    tmp_clone="$(mktemp -d)/shellspec"
    # Clone the pinned release tag, then `make install` into the env prefix
    # so shellspec only exists when 'mdtk' is active. No curl|sh.
    if git clone --branch "${shellspec_version}" --depth 1 \
            "https://github.com/shellspec/shellspec.git" "$tmp_clone"; then
        if make -C "$tmp_clone" install PREFIX="${CONDA_PREFIX}"; then
            echo "SUCCESS shellspec ${shellspec_version} installed."
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
    echo "SUCCESS shellcheck already installed at ${shellcheck_bin}"
else
    echo "INFO  shellcheck not found. Installing into the env..."
    # shellcheck is a real conda-forge package, so conda install works cleanly.
    if conda install -y -c conda-forge -n mdtk "shellcheck=0.11.0"; then
        echo "SUCCESS shellcheck installed."
    else
        echo "WARNING shellcheck install failed (linting optional for now)." >&2
        echo "  Fix: conda install -c conda-forge -n mdtk shellcheck" >&2
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
echo "SUCCESS Linked 'mdtk' -> ${mdtk_link}"

# Done -------------------------------------------------------
echo ""
echo "SUCCESS All set. Try:"
echo "  mdtk version"
echo "  mdtk help"
echo "  make test"
