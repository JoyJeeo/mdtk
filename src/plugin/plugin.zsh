#!/usr/bin/env zsh
# ============================================================
# File:    src/plugin/plugin.zsh
# Purpose: Discover and explicitly execute user-installed MDTK plugins.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Plugins are readable `.zsh` files stored in MDTK's XDG data directory.
#   A plugin file must define `mdtk_plugin_main "$@"`. MDTK discovers plugins
#   only when `mdtk plugin` is invoked and loads only the plugin selected by an
#   explicit `run` command, keeping startup and unrelated commands unchanged.
#
# Security
#   Plugins execute as the current user and are not sandboxed. Names are
#   restricted to lowercase safe characters, and symlinked/non-regular files
#   are rejected so discovery cannot escape the plugin directory implicitly.
#
# Location
#   $MDTK_PLUGIN_DIR                         when explicitly set
#   $XDG_DATA_HOME/mdtk/plugins              when XDG_DATA_HOME is set
#   $HOME/.local/share/mdtk/plugins          otherwise
#
# Parameters (mdtk_plugin_dispatch)
#   list                  Print valid plugin names, one per line.
#   path                  Print the plugin directory.
#   run <name> [args...]  Load a plugin and call its entry point.
#   help                  Show usage.
#
# Return
#   0  command completed successfully.
#   1  invalid input, unsafe/missing plugin, or load failure.
#   Any other status is preserved from the plugin entry point.
#
# Example
#   mdtk plugin path
#   mdtk plugin list
#   mdtk plugin run hello world
# ============================================================

# Shared stateless presentation utility.
source "${${(%):-%x}:A:h:h}/utils/color.zsh"

# ------------------------------------------------------------
# _mdtk_plugin_dir
# ------------------------------------------------------------
# Description: Resolve the user plugin directory without creating it.
# Parameters: none. Return: 0; prints an absolute path.
# Example: plugin_dir="$(_mdtk_plugin_dir)"
# ------------------------------------------------------------
_mdtk_plugin_dir() {
    if [[ -n "${MDTK_PLUGIN_DIR:-}" ]]; then
        echo "${MDTK_PLUGIN_DIR:a}"
        return 0
    fi
    local base="${XDG_DATA_HOME:-${HOME:-/tmp}/.local/share}"
    echo "${base:a}/mdtk/plugins"
}

# ------------------------------------------------------------
# _mdtk_plugin_name_is_valid
# ------------------------------------------------------------
# Description: Accept a bounded lowercase plugin name without path syntax.
# Parameters: $1 plugin name. Return: 0 valid; 1 invalid.
# Example: _mdtk_plugin_name_is_valid "hello-world"
# ------------------------------------------------------------
_mdtk_plugin_name_is_valid() {
    local name="${1:-}"
    [[ -n "$name" && ${#name} -le 64 ]] || return 1
    case "$name" in
        [a-z0-9]* ) ;;
        *) return 1 ;;
    esac
    case "$name" in
        *[!a-z0-9_-]*) return 1 ;;
    esac
    return 0
}

# ------------------------------------------------------------
# _mdtk_plugin_file
# ------------------------------------------------------------
# Description: Resolve a validated plugin name beneath the plugin directory.
# Parameters: $1 plugin name. Return: 0 + path; 1 invalid name.
# Example: _mdtk_plugin_file "hello"
# ------------------------------------------------------------
_mdtk_plugin_file() {
    local name="${1:-}"
    _mdtk_plugin_name_is_valid "$name" || return 1
    echo "$(_mdtk_plugin_dir)/${name}.zsh"
}

# ------------------------------------------------------------
# _mdtk_plugin_file_is_loadable
# ------------------------------------------------------------
# Description: Require a readable regular plugin file that is not a symlink.
# Parameters: $1 file path. Return: 0 loadable; 1 unsafe/unreadable.
# Example: _mdtk_plugin_file_is_loadable "$file"
# ------------------------------------------------------------
_mdtk_plugin_file_is_loadable() {
    local file="${1:-}"
    [[ -n "$file" && -f "$file" && -r "$file" && ! -L "$file" ]]
}

# ------------------------------------------------------------
# _mdtk_plugin_list
# ------------------------------------------------------------
# Description: Print valid, loadable plugin names in byte-sorted order.
# Parameters: none. Return: 0, including when the directory is absent/empty.
# Example: _mdtk_plugin_list
# ------------------------------------------------------------
_mdtk_plugin_list() {
    local dir="$(_mdtk_plugin_dir)"
    [[ -d "$dir" ]] || return 0

    local file name
    local -a names=()
    for file in "${dir}"/*.zsh(N); do
        _mdtk_plugin_file_is_loadable "$file" || continue
        name="${file:t:r}"
        _mdtk_plugin_name_is_valid "$name" || continue
        names+=("$name")
    done
    (( ${#names[@]} )) || return 0
    local LC_ALL=C
    printf '%s\n' "${(@on)names}"
    return 0
}

# ------------------------------------------------------------
# _mdtk_plugin_run
# ------------------------------------------------------------
# Description: Load one validated plugin and invoke `mdtk_plugin_main`.
# Parameters: $1 plugin name; $2... arguments passed without re-evaluation.
# Return: plugin status; 1 for validation, file, load, or contract errors.
# Example: _mdtk_plugin_run "hello" "world"
# ------------------------------------------------------------
_mdtk_plugin_run() {
    local name="${1:-}"
    shift 2>/dev/null
    if ! _mdtk_plugin_name_is_valid "$name"; then
        mdtk_utils_color_log "error" "Invalid plugin name: ${name:-<empty>}" >&2
        return 1
    fi

    local file
    file="$(_mdtk_plugin_file "$name")" || return 1
    if ! _mdtk_plugin_file_is_loadable "$file"; then
        mdtk_utils_color_log "error" "Plugin is missing or unsafe: ${name}" >&2
        mdtk_utils_color_log "info" "Plugin directory: $(_mdtk_plugin_dir)" >&2
        return 1
    fi

    unfunction mdtk_plugin_main 2>/dev/null || true
    if ! source "$file"; then
        mdtk_utils_color_log "error" "Could not load plugin: ${name}" >&2
        return 1
    fi
    if (( ! ${+functions[mdtk_plugin_main]} )); then
        mdtk_utils_color_log "error" "Plugin does not define mdtk_plugin_main: ${name}" >&2
        return 1
    fi

    mdtk_plugin_main "$@"
    return $?
}

# ------------------------------------------------------------
# _mdtk_plugin_usage
# ------------------------------------------------------------
# Description: Print Plugin CLI usage and the executable plugin contract.
# Parameters: none. Return: 0.
# Example: _mdtk_plugin_usage
# ------------------------------------------------------------
_mdtk_plugin_usage() {
    cat <<'EOF'
Usage: mdtk plugin <subcommand> [args]

Subcommands:
  list                  List available plugins.
  path                  Print the plugin directory.
  run <name> [args...]  Run a plugin and pass its arguments unchanged.
  help                  Show this message.

A plugin is a <name>.zsh file that defines:
  mdtk_plugin_main() { ... }

Plugins run as your user and are not sandboxed. Review them before use.

Example:
  mdtk plugin run hello world
EOF
}

# ------------------------------------------------------------
# mdtk_plugin_dispatch
# ------------------------------------------------------------
# Description: Route Plugin CLI subcommands.
# Parameters: documented in the file header. Return: command-specific status.
# Example: mdtk_plugin_dispatch list
# ------------------------------------------------------------
mdtk_plugin_dispatch() {
    local subcommand="${1:-}"
    shift 2>/dev/null
    case "$subcommand" in
        list)
            (( $# == 0 )) || {
                mdtk_utils_color_log "error" "Plugin list does not accept arguments." >&2
                return 1
            }
            _mdtk_plugin_list
            ;;
        path)
            (( $# == 0 )) || {
                mdtk_utils_color_log "error" "Plugin path does not accept arguments." >&2
                return 1
            }
            _mdtk_plugin_dir
            ;;
        run)
            local name="${1:-}"
            shift 2>/dev/null
            _mdtk_plugin_run "$name" "$@"
            ;;
        help|--help|-h)
            _mdtk_plugin_usage
            ;;
        "")
            _mdtk_plugin_usage
            return 1
            ;;
        *)
            mdtk_utils_color_log "error" "Unknown plugin subcommand: ${subcommand}" >&2
            mdtk_utils_color_log "info" "Run 'mdtk plugin help' for usage." >&2
            return 1
            ;;
    esac
}
