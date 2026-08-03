#!/usr/bin/env zsh
# ============================================================
# File:    src/config/config.zsh
# Purpose: Read/write user configuration for MDTK.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   The Config module. Stores user preferences as a simple key=value
#   file at an XDG-aware location. Provides a small get/set API for
#   other modules (sourced as a library is NOT allowed per
#   .ai/ARCHITECTURE.md — modules do not source each other; instead
#   callers go through the dispatcher, or read the same file via the
#   cache module in their own issues). For v0.1 the CLI surface is
#   the public contract.
#
#   Public entry point (called by the dispatcher):
#       mdtk_config_dispatch "$@"
#   Public functions (other modules adopt in their own issues, via
#   the dispatcher, not by sourcing this file):
#       mdtk_config_get <key>
#       mdtk_config_set <key> <value>
#
# Storage format
#   One `key=value` pair per line. Values are stored verbatim (no
#   quoting) — keep values single-token in v0.1. Keys are [a-z_]+.
#
# Location
#   $XDG_CONFIG_HOME/mdtk/config  if XDG_CONFIG_HOME is set and non-empty.
#   $HOME/.config/mdtk/config     otherwise.
#   Falls back to a tmp path if HOME is unset (mainly for tests).
#
# Exit-code policy
#   - get of a missing key: prints nothing, returns 1.
#   - get of a set key: prints value, returns 0.
#   - set: returns 0 on success, 1 on bad args / IO failure.
#   - dispatch usage error: returns 1.
#
# Parameters (mdtk_config_dispatch)
#   $1    subcommand: get | set | list | path | help
#   $@..  key [/ value]
#
# Return
#   0  success.
#   1  usage error, missing key, or IO failure.
#
# Example
#   mdtk config set color on
#   mdtk config get color
#   # => on
#   mdtk config list
#   mdtk config path
# ============================================================

# Library: utils/path owns XDG-aware path resolution.
source "${${(%):-%x}:A:h:h}/utils/path.zsh"
# Library: utils/color owns shared error presentation.
source "${${(%):-%x}:A:h:h}/utils/color.zsh"

# ------------------------------------------------------------
# _mdtk_config_file
# ------------------------------------------------------------
# Description
#   Resolve the path to the user config file through the shared,
#   XDG-aware path utility.
#
# Parameters
#   None.
#
# Return
#   0. Prints the absolute config file path to stdout.
# ------------------------------------------------------------
_mdtk_config_file() {
    mdtk_utils_path_config
}

# ------------------------------------------------------------
# _mdtk_config_dir
# ------------------------------------------------------------
# Description: resolve the config *directory* (parent of the file).
# Parameters: none. Return: 0; prints dir path.
# ------------------------------------------------------------
_mdtk_config_dir() {
    local file
    file="$(_mdtk_config_file)"
    echo "${file:a:h}"
}

# ------------------------------------------------------------
# mdtk_config_get
# ------------------------------------------------------------
# Description
#   Print the value for a key, or nothing if absent.
# Parameters
#   $1    key
# Return
#   0  key found (value printed).
#   1  key absent or no key given.
# Example
#   mdtk_config_get color
# ------------------------------------------------------------
mdtk_config_get() {
    local key="$1"
    if [[ -z "$key" ]]; then
        return 1
    fi
    local file
    file="$(_mdtk_config_file)"
    if [[ ! -r "$file" ]]; then
        return 1
    fi
    # Match `key=` at start of line; print the value (everything after =).
    local line
    while IFS= read -r line; do
        if [[ "$line" == "${key}="* ]]; then
            echo "${line#${key}=}"
            return 0
        fi
    done < "$file"
    return 1
}

# ------------------------------------------------------------
# mdtk_config_set
# ------------------------------------------------------------
# Description
#   Set a key=value pair, creating the config file/dir if needed.
#   Overwrites an existing key; appends a new one otherwise.
# Parameters
#   $1    key   ([a-z_]+ recommended)
#   $2    value (single token in v0.1)
# Return
#   0  stored.
#   1  bad args or IO failure.
# Example
#   mdtk_config_set color on
# ------------------------------------------------------------
mdtk_config_set() {
    local key="$1"
    local value="$2"
    if [[ -z "$key" ]]; then
        return 1
    fi
    local dir file
    dir="$(_mdtk_config_dir)"
    file="$(_mdtk_config_file)"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || return 1
    fi
    # Rewrite the file: drop any existing `key=`, then append the new pair.
    local tmp
    tmp="${file}.tmp.$$"
    {
        if [[ -r "$file" ]]; then
            local line
            while IFS= read -r line; do
                if [[ "$line" != "${key}="* ]]; then
                    echo "$line"
                fi
            done < "$file"
        fi
        echo "${key}=${value}"
    } > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
    mv -f "$tmp" "$file" || { rm -f "$tmp"; return 1; }
    return 0
}

# ------------------------------------------------------------
# _mdtk_config_list
# ------------------------------------------------------------
# Description: print all key=value pairs in storage order.
# Parameters: none. Return: 0 (prints nothing if no file).
# ------------------------------------------------------------
_mdtk_config_list() {
    local file
    file="$(_mdtk_config_file)"
    if [[ -r "$file" ]]; then
        cat "$file"
    fi
    return 0
}

# ------------------------------------------------------------
# _mdtk_config_usage
# ------------------------------------------------------------
# Description: print a friendly usage message.
# Parameters: none. Return: 0.
# ------------------------------------------------------------
_mdtk_config_usage() {
    cat <<'EOF'
Usage: mdtk config <subcommand> [args]

Subcommands:
  get <key>            Print the value of a key (exit 1 if absent).
  set <key> <value>    Set a key to a value.
  list                 Print all key=value pairs.
  path                 Print the config file path.
  help                 Show this message.

Example:
  mdtk config set color on
  mdtk config get color
EOF
}

# ------------------------------------------------------------
# mdtk_config_dispatch
# ------------------------------------------------------------
# Description
#   CLI entry point. Routes get/set/list/path/help.
# Parameters
#   $1    subcommand
#   $@..  arguments
# Return
#   0  success.
#   1  usage error or missing key.
# Example
#   mdtk_config_dispatch set color on
# ------------------------------------------------------------
mdtk_config_dispatch() {
    local sub="$1"
    shift 2>/dev/null

    case "$sub" in
        get)
            local key="$1"
            if [[ -z "$key" ]]; then
                _mdtk_config_usage
                return 1
            fi
            mdtk_config_get "$key"
            return $?
            ;;
        set)
            local key="$1"
            local value="$2"
            if [[ -z "$key" ]]; then
                _mdtk_config_usage
                return 1
            fi
            mdtk_config_set "$key" "$value"
            return $?
            ;;
        list)
            _mdtk_config_list
            return 0
            ;;
        path)
            _mdtk_config_file
            return 0
            ;;
        help|--help|-h)
            _mdtk_config_usage
            return 0
            ;;
        "")
            _mdtk_config_usage
            return 1
            ;;
        *)
            mdtk_utils_color_log "error" "Unknown config subcommand: ${sub}" >&2
            _mdtk_config_usage
            return 1
            ;;
    esac
}
