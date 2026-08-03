#!/usr/bin/env zsh
# ============================================================
# File:    scripts/mdtk.zsh
# Purpose: Shell hook for MDTK's command-not-found handler.
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Source this file from your ~/.zshrc to get a smart
#   command-not-found handler:
#
#       source /path/to/mdtk/scripts/mdtk.zsh
#
#   When zsh can't find a command, it calls
#   `command_not_found_handler`, which here delegates to
#   `mdtk cnf <cmd> [args...]`. CNF classifies the complete field,
#   then looks command-shaped input up in MDTK's full offline index
#   and returns without waiting for Homebrew or the network.
#
#   This file defines the handler and registers native Zsh completion.
#   It does not load an MDTK module or run `compinit` at shell startup;
#   the `mdtk cnf` call remains on-demand.
#
# Parameters (handler)
#   $1    the command name that was not found.
#   $2... the command's original arguments.
#
# Return
#   The handler returns 0 (so zsh does not print its own "command
#   not found" line — we already gave a friendlier message).
#
# Example
#   # in ~/.zshrc:
#   source "$HOME/.mdtk/scripts/mdtk.zsh"
#   rg file        # => [SUCCESS] Found: ... [INFO] Run: brew install ripgrep
#   mdtk upd<Tab>  # => mdtk update
# ============================================================

# Add MDTK's native completion before compinit, or register it immediately
# when the user's shell framework has already initialized completion.
_mdtk_register_completion() {
    local completion_dir="${${(%):-%x}:A:h:h}/completions"
    if (( ! ${fpath[(Ie)$completion_dir]} )); then
        fpath=("$completion_dir" $fpath)
    fi
    if (( ${+functions[compdef]} )); then
        autoload -Uz _mdtk
        compdef _mdtk mdtk
    fi
}

_mdtk_register_completion
unfunction _mdtk_register_completion

# Only define if zsh supports command_not_found_handler.
if (( ${+functions[command_not_found_handler]} )); then
    # Already defined (e.g. by another tool). Don't clobber.
    :
else
    command_not_found_handler() {
        # Be quiet if mdtk is not on PATH (e.g. env not active).
        if (( ${+commands[mdtk]} )); then
            mdtk cnf "$@" 2>/dev/null
        fi
        return 0
    }
fi
