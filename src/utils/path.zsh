#!/usr/bin/env zsh
# ============================================================
# File:    src/utils/path.zsh
# Purpose: Path-resolution helpers shared across modules.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Stateless helpers that resolve project- and user-level paths
#   without hardcoding them. This is the landing place for the
#   MASTER_PROMPT rule "Never hardcode paths". Utils are a library,
#   not a module (no dispatch function, never call back upward).
#
# Public functions
#   mdtk_utils_path_root      -> project root (where .shellspec lives)
#   mdtk_utils_path_config    -> user config file path (XDG-aware)
#   mdtk_utils_path_cache_dir -> user cache directory (XDG-aware)
#   mdtk_utils_path_cache_file <name> -> a cache file under the cache dir
#
# Parameters
#   per function (see headers).
#
# Return
#   0. Each prints a path to stdout.
#
# Example
#   source src/utils/path.zsh
#   echo "$(mdtk_utils_path_config)"
# ============================================================

# ------------------------------------------------------------
# mdtk_utils_path_root
# ------------------------------------------------------------
# Description: resolve the MDTK project root (parent of src/).
# Parameters: none.
# Return: 0; prints the root path.
# Example: root="$(mdtk_utils_path_root)"
# ------------------------------------------------------------
mdtk_utils_path_root() {
    local self
    self="${(%):-%x}"
    local this_dir
    this_dir="${self:A:h}"
    # this_dir = src/utils; root = two levels up.
    echo "${this_dir:a:h:h}"
}

# ------------------------------------------------------------
# mdtk_utils_path_config
# ------------------------------------------------------------
# Description: resolve the user config file path (XDG-aware).
#   $XDG_CONFIG_HOME/mdtk/config  if XDG_CONFIG_HOME set and non-empty,
#   $HOME/.config/mdtk/config     otherwise,
#   /tmp/mdtk/config             if HOME is also unset (tests).
# Parameters: none.
# Return: 0; prints the config file path.
# ------------------------------------------------------------
mdtk_utils_path_config() {
    local base
    base="${XDG_CONFIG_HOME:-}"
    if [[ -z "$base" ]]; then
        base="${HOME:-/tmp}"
        base="${base}/.config"
    fi
    echo "${base}/mdtk/config"
}

# ------------------------------------------------------------
# mdtk_utils_path_cache_dir
# ------------------------------------------------------------
# Description: resolve the user cache directory (XDG-aware).
#   $XDG_CACHE_HOME/mdtk   if XDG_CACHE_HOME set and non-empty,
#   $HOME/.cache/mdtk      otherwise,
#   /tmp/mdtk-cache        if HOME is also unset (tests).
# Parameters: none.
# Return: 0; prints the cache directory path.
# ------------------------------------------------------------
mdtk_utils_path_cache_dir() {
    local base
    base="${XDG_CACHE_HOME:-}"
    if [[ -z "$base" ]]; then
        base="${HOME:-/tmp}"
        base="${base}/.cache"
    fi
    echo "${base}/mdtk"
}

# ------------------------------------------------------------
# mdtk_utils_path_cache_file
# ------------------------------------------------------------
# Description: resolve a named cache file under the cache dir.
# Parameters: $1 name (e.g. "command_index")
# Return: 0; prints the cache file path.
# Example: mdtk_utils_path_cache_file "command_index"
# ------------------------------------------------------------
mdtk_utils_path_cache_file() {
    local name="$1"
    local dir
    dir="$(mdtk_utils_path_cache_dir)"
    echo "${dir}/${name}"
}
