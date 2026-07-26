#!/usr/bin/env zsh
# ============================================================
# File:    src/utils/shell.zsh
# Purpose: zsh capability / compatibility helpers shared across modules.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Stateless helpers that detect zsh version and read optional env
#   vars safely (without tripping `set -u`, which .ai/STYLE_GUIDE.md
#   forbids in sourced libraries). Utils are a library, not a module
#   (no dispatch function, never call back upward).
#
# Public functions
#   mdtk_utils_shell_zsh_version      -> major.minor string
#   mdtk_utils_shell_has_option <name> -> 0 if option is set
#   mdtk_utils_shell_env_get <name>    -> print env var or default
#
# Parameters: per function (see headers).
# Return: per function.
# Example
#   source src/utils/shell.zsh
#   echo "$(mdtk_utils_shell_zsh_version)"
#   mdtk_utils_shell_env_get "MDTK_DEBUG" "0"
# ============================================================

# ------------------------------------------------------------
# mdtk_utils_shell_zsh_version
# ------------------------------------------------------------
# Description: print the running zsh version (ZSH_VERSION).
# Parameters: none.
# Return: 0; prints the version string.
# Example: mdtk_utils_shell_zsh_version  # => 5.9
# ------------------------------------------------------------
mdtk_utils_shell_zsh_version() {
    echo "$ZSH_VERSION"
}

# ------------------------------------------------------------
# mdtk_utils_shell_has_option
# ------------------------------------------------------------
# Description: check whether a shell option (setopt name) is on.
# Parameters: $1 option name (e.g. pipefail, err_exit).
# Return: 0 if on; 1 if off / unknown.
# Example: if mdtk_utils_shell_has_option pipefail; then ...
# ------------------------------------------------------------
mdtk_utils_shell_has_option() {
    local name="$1"
    if [[ -z "$name" ]]; then
        return 1
    fi
    local on
    on="${options[$name]:-off}"
    if [[ "$on" == "on" ]]; then
        return 0
    fi
    return 1
}

# ------------------------------------------------------------
# mdtk_utils_shell_env_get
# ------------------------------------------------------------
# Description: safely read an optional env var with a default.
#   Avoids `set -u` hazards in sourced libraries.
# Parameters: $1 name, $2 default (optional).
# Return: 0; prints the value or default.
# Example: mdtk_utils_shell_env_get "MDTK_DEBUG" "0"
# ------------------------------------------------------------
mdtk_utils_shell_env_get() {
    local name="$1"
    local default="${2:-}"
    local value
    eval "value=\"\${${name}:-}\""
    if [[ -z "$value" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}
