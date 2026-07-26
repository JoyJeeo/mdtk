#!/usr/bin/env zsh
# ============================================================
# File:    src/dispatcher.zsh
# Purpose: Route an mdtk subcommand to the matching module.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   The dispatcher is the only piece that knows about every module.
#   Entry point (bin/mdtk) calls mdtk_dispatch "$@".
#   Each feature module exposes mdtk_<name>_dispatch().
#
#   This is infrastructure (see .ai/ARCHITECTURE.md: Entry -> Dispatcher
#   -> Modules), not a feature module. Module files live at
#   src/<module>/<module>.zsh and are stubs until their TASK.md is opened.
#
# Parameters
#   $1    subcommand name (logger, config, cache, ...)
#   $@..  remaining args forwarded to the module
#
# Return
#   0 on success / known built-in handled.
#   1 on missing command or unknown subcommand.
#
# Example
#   mdtk_dispatch version
#   mdtk_dispatch logger --info "hello"
# ============================================================

# ------------------------------------------------------------
# Private: absolute directory of this file (src/).
# ------------------------------------------------------------
# Description
#   Resolve the src/ directory so module stubs can be sourced by
#   absolute path regardless of where bin/mdtk is invoked from.
#   Each module lives at src/<module>/<module>.zsh.
#
# Parameters
#   None.
#
# Return
#   0. Prints the src/ directory path to stdout.
# ------------------------------------------------------------
_mdtk_src_dir() {
    local script
    script="${(%):-%x}"
    local dir
    dir="${script:A:h}"
    echo "$dir"
}

# ------------------------------------------------------------
# mdtk_dispatch
# ------------------------------------------------------------
# Description
#   Route the first argument to the matching module dispatch
#   function, or handle a built-in command (version/help).
#
# Parameters
#   $1    subcommand
#   $@..  forwarded to the module
#
# Return
#   0  command handled successfully
#   1  no command given, or unknown command
#
# Example
#   mdtk_dispatch version
#   mdtk_dispatch logger --info "boot"
# ------------------------------------------------------------
mdtk_dispatch() {
    local cmd="$1"
    shift 2>/dev/null

    local src_dir
    src_dir="$(_mdtk_src_dir)"

    # No command at all -> show help.
    if [[ -z "$cmd" ]]; then
        mdtk_dispatch_help
        return 1
    fi

    case "$cmd" in
        version)
            echo "mdtk ${MDTK_VERSION}"
            return 0
            ;;
        help)
            mdtk_dispatch_help
            return 0
            ;;
        logger|config|cache|search|install|doctor|plugin)
            source "${src_dir}/${cmd}/${cmd}.zsh"
            "mdtk_${cmd}_dispatch" "$@"
            return $?
            ;;
        *)
            echo "Unknown command: ${cmd}"
            echo ""
            echo "Run 'mdtk help' to see what is available."
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# mdtk_dispatch_help
# ------------------------------------------------------------
# Description
#   Print the list of known commands in plain language.
#
# Parameters
#   None.
#
# Return
#   Always 0.
# ------------------------------------------------------------
mdtk_dispatch_help() {
    cat <<'EOF'
mdtk - Mac Developer Toolkit

Available commands:

  version    Show the installed version.
  help       Show this help message.

  logger     Log messages (not implemented yet).
  config     Manage configuration (not implemented yet).
  cache      Manage the command cache (not implemented yet).
  search     Search packages (not implemented yet).
  install    Recommend and run an install (not implemented yet).
  doctor     Diagnose the developer environment (not implemented yet).
  plugin     Manage plugins (not implemented yet).

Not implemented commands are tracked in .ai/TASK.md.
EOF
}

# Make sure the version constant is available.
source "$(_mdtk_src_dir)/version.zsh"
