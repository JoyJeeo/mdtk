# shellcheck shell=sh
# ============================================================
# File:    tests/completion/completion_spec.sh
# Purpose: Tests for native Zsh completion (Issue #057).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Exercises the completion function with mocked Zsh completion helpers and
#   verifies shell-hook registration in isolated function scopes. Covers
#   commands, subcommands, options, pre/post-compinit registration, repeated
#   sourcing, Unicode/whitespace input, no external calls, and performance.
#
# Run
#   make testone FILE=tests/completion/completion_spec.sh
# ============================================================

MDTK_COMPLETION_DIR="${SHELLSPEC_PROJECT_ROOT}/completions"
MDTK_SHELL_HOOK="${SHELLSPEC_PROJECT_ROOT}/scripts/mdtk.zsh"

_mdtk_completion_prepare() {
    unfunction _mdtk 2>/dev/null || true
    fpath=("$MDTK_COMPLETION_DIR" $fpath)
    autoload -Uz _mdtk
}

_mdtk_completion_describe() {
    local array_name="${@[-1]}"
    print -l -- "${(@P)array_name}"
}

_mdtk_completion_top() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk "")
    CURRENT=2
    _mdtk
}

_mdtk_completion_config() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk config "")
    CURRENT=3
    _mdtk
}

_mdtk_completion_index() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk index "")
    CURRENT=3
    _mdtk
}

_mdtk_completion_cache() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk cache "")
    CURRENT=3
    _mdtk
}

# Description: Print static Plugin subcommand completion candidates.
# Parameters: none. Return: completion helper status.
# Example: _mdtk_completion_plugin
_mdtk_completion_plugin() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk plugin "")
    CURRENT=3
    _mdtk
}

# Description: Print the positional prompt for a Plugin run name.
# Parameters: none. Return: completion helper status.
# Example: _mdtk_completion_plugin_name
_mdtk_completion_plugin_name() {
    _mdtk_completion_prepare
    _message() { print -r -- "$1"; }
    words=(mdtk plugin run "")
    CURRENT=4
    _mdtk
}

_mdtk_completion_logger_options() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk logger --)
    CURRENT=3
    _mdtk
}

_mdtk_completion_search_options() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk search --)
    CURRENT=3
    _mdtk
}

_mdtk_completion_update_options() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk update --)
    CURRENT=3
    _mdtk
}

_mdtk_completion_uninstall_options() {
    _mdtk_completion_prepare
    _describe() { _mdtk_completion_describe "$@"; }
    words=(mdtk uninstall --)
    CURRENT=3
    _mdtk
}

_mdtk_completion_unicode_argument() {
    _mdtk_completion_prepare
    _message() { print -r -- "$1"; }
    words=(mdtk search "中文 query")
    CURRENT=3
    _mdtk
}

_mdtk_completion_register_before_compinit() {
    unfunction compdef 2>/dev/null || true
    fpath=(/tmp/mdtk-other-completions)
    source "$MDTK_SHELL_HOOK"
    print -r -- "$fpath[1]"
}

_mdtk_completion_register_after_compinit() {
    fpath=(/tmp/mdtk-other-completions)
    compdef() { print -r -- "compdef:$*"; }
    source "$MDTK_SHELL_HOOK"
    print -r -- "fpath:$fpath[1]"
}

_mdtk_completion_register_twice() {
    unfunction compdef 2>/dev/null || true
    fpath=(/tmp/mdtk-other-completions)
    source "$MDTK_SHELL_HOOK"
    source "$MDTK_SHELL_HOOK"
    local entry count=0
    for entry in "$fpath[@]"; do
        [[ "$entry" == "$MDTK_COMPLETION_DIR" ]] && (( count++ ))
    done
    print -r -- "$count"
}

_mdtk_completion_without_external_calls() {
    _mdtk_completion_prepare
    local called=0
    mdtk() { (( called++ )); }
    brew() { (( called++ )); }
    git() { (( called++ )); }
    _describe() { :; }
    words=(mdtk "")
    CURRENT=2
    _mdtk
    words=(mdtk update --)
    CURRENT=3
    _mdtk
    words=(mdtk plugin "")
    CURRENT=3
    _mdtk
    (( called == 0 ))
}

_mdtk_completion_performance() {
    _mdtk_completion_prepare
    _describe() { :; }
    zmodload zsh/datetime
    local start="$EPOCHREALTIME"
    local i
    for i in {1..1000}; do
        words=(mdtk "")
        CURRENT=2
        _mdtk
    done
    local elapsed=$(( EPOCHREALTIME - start ))
    (( elapsed < 2.0 ))
}

Describe 'native Zsh completion'
    It 'completes every top-level command'
        When call _mdtk_completion_top
        The output should include 'version:'
        The output should include 'logger:'
        The output should include 'config:'
        The output should include 'cache:'
        The output should include 'search:'
        The output should include 'install:'
        The output should include 'uninstall:'
        The output should include 'update:'
        The output should include 'index:'
        The output should include 'cnf:'
        The output should include 'doctor:'
        The output should include 'plugin:'
        The status should be successful
    End

    It 'completes config subcommands'
        When call _mdtk_completion_config
        The output should include 'get:'
        The output should include 'set:'
        The output should include 'list:'
        The output should include 'path:'
        The output should include '--help:'
        The output should include '-h:'
        The status should be successful
    End

    It 'completes index subcommands'
        When call _mdtk_completion_index
        The output should include 'build:'
        The output should include 'lookup:'
        The output should include 'path:'
        The output should include '--help:'
        The status should be successful
    End

    It 'completes cache subcommands'
        When call _mdtk_completion_cache
        The output should include 'get:'
        The output should include 'set:'
        The output should include 'clean:'
        The output should include 'list:'
        The output should include '--help:'
        The status should be successful
    End

    It 'completes plugin subcommands without scanning plugins'
        When call _mdtk_completion_plugin
        The output should include 'list:'
        The output should include 'path:'
        The output should include 'run:'
        The output should include 'help:'
        The output should include '--help:'
        The status should be successful
    End

    It 'prompts for the plugin name without dynamic lookup'
        When call _mdtk_completion_plugin_name
        The output should equal 'plugin name'
        The status should be successful
    End

    It 'completes logger options'
        When call _mdtk_completion_logger_options
        The output should include '--info:'
        The output should include '--success:'
        The output should include '--warning:'
        The output should include '--error:'
        The output should include '--debug:'
        The output should include '--no-color:'
        The output should include '--quiet:'
        The status should be successful
    End

    It 'completes help options for positional commands'
        When call _mdtk_completion_search_options
        The output should include '--help:'
        The output should include '-h:'
        The status should be successful
    End

    It 'completes update options'
        When call _mdtk_completion_update_options
        The output should include '--ref:'
        The output should include '--coder:'
        The output should include '--help:'
        The status should be successful
    End

    It 'completes uninstall options'
        When call _mdtk_completion_uninstall_options
        The output should include '--yes:'
        The output should include '--keep-config:'
        The output should include '--dry-run:'
        The status should be successful
    End

    It 'accepts Unicode and whitespace positional input'
        When call _mdtk_completion_unicode_argument
        The output should include 'search query'
        The status should be successful
    End

    It 'adds fpath before compinit without initializing completion'
        When call _mdtk_completion_register_before_compinit
        The output should equal "$MDTK_COMPLETION_DIR"
        The status should be successful
    End

    It 'registers compdef after completion is initialized'
        When call _mdtk_completion_register_after_compinit
        The output should include 'compdef:_mdtk mdtk'
        The output should include "fpath:$MDTK_COMPLETION_DIR"
        The status should be successful
    End

    It 'does not duplicate fpath on repeated hook loading'
        When call _mdtk_completion_register_twice
        The output should equal '1'
        The status should be successful
    End

    It 'does not invoke MDTK, Homebrew, or Git'
        When call _mdtk_completion_without_external_calls
        The status should be successful
    End

    It 'completes 1000 top-level requests within two seconds'
        When call _mdtk_completion_performance
        The status should be successful
    End
End
