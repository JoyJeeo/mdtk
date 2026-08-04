# shellcheck shell=sh
# ============================================================
# File:    tests/plugin/plugin_spec.sh
# Purpose: Behavior tests for the Plugin module (Issue #060).
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Exercises XDG discovery, deterministic listing, explicit loading, argument
#   forwarding, exit-code preservation, unsafe input, broken plugin contracts,
#   Unicode data, empty input, and a directory containing 1,000 plugins.
#
# Run
#   make testone FILE=tests/plugin/plugin_spec.sh
# ============================================================

. "${SHELLSPEC_PROJECT_ROOT}/src/plugin/plugin.zsh"

_MDTK_PLUGIN_TMP="$(mktemp -d)"

# Description: Reset the isolated plugin directory and relevant environment.
# Parameters: none. Return: 0.
# Example: mdtk_plugin_setup
mdtk_plugin_setup() {
    rm -rf -- "${_MDTK_PLUGIN_TMP}"
    mkdir -p "${_MDTK_PLUGIN_TMP}/data/mdtk/plugins" "${_MDTK_PLUGIN_TMP}/home"
    export HOME="${_MDTK_PLUGIN_TMP}/home"
    export XDG_DATA_HOME="${_MDTK_PLUGIN_TMP}/data"
    unset MDTK_PLUGIN_DIR
    unset NO_COLOR
    unfunction mdtk_plugin_main 2>/dev/null || true
}

# Description: Write a plugin that prints each received argument verbatim.
# Parameters: $1 plugin name. Return: the write operation's status.
# Example: mdtk_plugin_write_echo "hello"
mdtk_plugin_write_echo() {
    local name="$1"
    printf '%s\n' \
        'mdtk_plugin_main() {' \
        '    printf "arg=<%s>\\n" "$@"' \
        '}' > "${XDG_DATA_HOME}/mdtk/plugins/${name}.zsh"
}

# Description: Create 1,000 valid plugins and print listing summary fields.
# Parameters: none. Return: 0 when listing succeeds.
# Example: mdtk_plugin_large_listing
mdtk_plugin_large_listing() {
    local index name
    for index in {1..1000}; do
        name="plugin$(printf '%04d' "$index")"
        printf '%s\n' 'mdtk_plugin_main() { return 0; }' > \
            "${XDG_DATA_HOME}/mdtk/plugins/${name}.zsh"
    done
    local listing
    listing="$(_mdtk_plugin_list)" || return 1
    local -a names=("${(@f)listing}")
    printf 'count=%s\nfirst=%s\nlast=%s\n' \
        "${#names[@]}" "${names[1]}" "${names[-1]}"
}

# Description: Invoke a plugin with an oversized invalid name.
# Parameters: none. Return: the dispatch status.
# Example: mdtk_plugin_run_large_name
mdtk_plugin_run_large_name() {
    local name=""
    local index
    for index in {1..65}; do
        name="${name}x"
    done
    mdtk_plugin_dispatch run "$name"
}

Describe 'mdtk plugin'
    BeforeEach 'mdtk_plugin_setup'

    It 'prints the XDG plugin directory without creating it'
        rm -rf -- "${XDG_DATA_HOME}/mdtk/plugins"
        When call mdtk_plugin_dispatch path
        The output should equal "${XDG_DATA_HOME}/mdtk/plugins"
        The path "${XDG_DATA_HOME}/mdtk/plugins" should not be exist
        The status should be successful
    End

    It 'honors an explicit plugin-directory override'
        export MDTK_PLUGIN_DIR="${_MDTK_PLUGIN_TMP}/custom plugins"
        When call mdtk_plugin_dispatch path
        The output should equal "${_MDTK_PLUGIN_TMP}/custom plugins"
        The status should be successful
    End

    It 'lists an absent directory as empty'
        rm -rf -- "${XDG_DATA_HOME}/mdtk/plugins"
        When call mdtk_plugin_dispatch list
        The output should be blank
        The status should be successful
    End

    It 'lists valid plugins in deterministic order and ignores unsafe files'
        printf '%s\n' 'mdtk_plugin_main() { :; }' > "${XDG_DATA_HOME}/mdtk/plugins/zeta.zsh"
        printf '%s\n' 'mdtk_plugin_main() { :; }' > "${XDG_DATA_HOME}/mdtk/plugins/alpha.zsh"
        printf '%s\n' 'mdtk_plugin_main() { :; }' > "${XDG_DATA_HOME}/mdtk/plugins/Invalid.zsh"
        printf '%s\n' 'mdtk_plugin_main() { :; }' > "${XDG_DATA_HOME}/mdtk/plugins/readme.txt"
        ln -s "${XDG_DATA_HOME}/mdtk/plugins/alpha.zsh" "${XDG_DATA_HOME}/mdtk/plugins/linked.zsh"
        When call mdtk_plugin_dispatch list
        The output should equal $'alpha\nzeta'
        The status should be successful
    End

    It 'does not load plugin code while listing'
        printf '%s\n' \
            'print loaded > "${XDG_DATA_HOME}/loaded"' \
            'mdtk_plugin_main() { :; }' > "${XDG_DATA_HOME}/mdtk/plugins/passive.zsh"
        When call mdtk_plugin_dispatch list
        The output should equal 'passive'
        The path "${XDG_DATA_HOME}/loaded" should not be exist
        The status should be successful
    End

    It 'loads a selected plugin and preserves argument boundaries'
        mdtk_plugin_write_echo "hello"
        When call mdtk_plugin_dispatch run hello "two words" '$(touch unsafe)' '中文'
        The output should equal $'arg=<two words>\narg=<$(touch unsafe)>\narg=<中文>'
        The path "${SHELLSPEC_PROJECT_ROOT}/unsafe" should not be exist
        The status should be successful
    End

    It 'preserves the plugin entry point exit status'
        printf '%s\n' 'mdtk_plugin_main() { return 7; }' > "${XDG_DATA_HOME}/mdtk/plugins/failing.zsh"
        When call mdtk_plugin_dispatch run failing
        The status should equal 7
    End

    It 'supports Unicode plugin output'
        printf '%s\n' 'mdtk_plugin_main() { print -r -- "你好，MDTK"; }' > "${XDG_DATA_HOME}/mdtk/plugins/greeting.zsh"
        When call mdtk_plugin_dispatch run greeting
        The output should equal '你好，MDTK'
        The status should be successful
    End

    It 'rejects a missing plugin'
        export NO_COLOR=1
        When call mdtk_plugin_dispatch run absent
        The error should include '[ERROR]   Plugin is missing or unsafe: absent'
        The error should include 'Plugin directory:'
        The status should be failure
    End

    It 'rejects an empty plugin name'
        When call mdtk_plugin_dispatch run
        The error should include 'Invalid plugin name: <empty>'
        The status should be failure
    End

    It 'rejects a symlinked plugin'
        printf '%s\n' 'mdtk_plugin_main() { :; }' > "${_MDTK_PLUGIN_TMP}/outside.zsh"
        ln -s "${_MDTK_PLUGIN_TMP}/outside.zsh" "${XDG_DATA_HOME}/mdtk/plugins/linked.zsh"
        When call mdtk_plugin_dispatch run linked
        The error should include 'missing or unsafe'
        The status should be failure
    End

    It 'rejects path traversal'
        When call mdtk_plugin_dispatch run ../outside
        The error should include 'Invalid plugin name'
        The status should be failure
    End

    It 'rejects a whitespace-only name'
        When call mdtk_plugin_dispatch run '   '
        The error should include 'Invalid plugin name'
        The status should be failure
    End

    It 'rejects a Unicode plugin name'
        When call mdtk_plugin_dispatch run '插件'
        The error should include 'Invalid plugin name'
        The status should be failure
    End

    It 'rejects a name longer than 64 characters'
        When call mdtk_plugin_run_large_name
        The error should include 'Invalid plugin name'
        The status should be failure
    End

    It 'rejects a plugin without the required entry point'
        printf '%s\n' 'plugin_other_function() { :; }' > "${XDG_DATA_HOME}/mdtk/plugins/incomplete.zsh"
        When call mdtk_plugin_dispatch run incomplete
        The error should include 'does not define mdtk_plugin_main'
        The status should be failure
    End

    It 'reports a plugin load failure'
        printf '%s\n' 'return 1' > "${XDG_DATA_HOME}/mdtk/plugins/broken.zsh"
        When call mdtk_plugin_dispatch run broken
        The error should include 'Could not load plugin: broken'
        The status should be failure
    End

    It 'requires a subcommand for empty input'
        When call mdtk_plugin_dispatch
        The output should include 'Usage: mdtk plugin'
        The status should be failure
    End

    It 'prints help successfully'
        When call mdtk_plugin_dispatch help
        The output should include 'Plugins run as your user and are not sandboxed.'
        The status should be successful
    End

    It 'rejects an unknown subcommand'
        When call mdtk_plugin_dispatch unknown
        The error should include 'Unknown plugin subcommand: unknown'
        The status should be failure
    End

    It 'rejects arguments to list and path'
        When call mdtk_plugin_dispatch list extra
        The error should include 'does not accept arguments'
        The status should be failure
    End

    It 'lists 1,000 plugins in deterministic order'
        When call mdtk_plugin_large_listing
        The output should include 'count=1000'
        The output should include 'first=plugin0001'
        The output should include 'last=plugin1000'
        The status should be successful
    End
End
