#!/usr/bin/env zsh
# ============================================================
# File:    src/doctor/doctor.zsh
# Purpose: Diagnose the local MDTK developer environment.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Runs read-only checks for MDTK's supported platform, Zsh, Homebrew,
#   executable, shell hook, offline command index, and user data paths.
#   Every failed check includes a direct recovery action. Doctor never
#   installs software, rebuilds data, changes files, or uses the network.
#
# Input
#   No arguments for diagnosis; "help" or "--help" for usage.
#
# Output
#   One colored status line per check and a final summary on stdout.
#   Argument errors are written to stderr.
#
# Return
#   0  every required check passed (warnings are allowed).
#   1  a required check failed or the arguments are invalid.
#
# Example
#   mdtk doctor
#   mdtk doctor --help
# ============================================================

source "${${(%):-%x}:A:h:h}/utils/path.zsh"
source "${${(%):-%x}:A:h:h}/utils/color.zsh"
source "${${(%):-%x}:A:h:h}/backends/homebrew.zsh"

# ------------------------------------------------------------
# _mdtk_doctor_root
# ------------------------------------------------------------
# Description: Resolve the checkout root that owns this Doctor module.
# Parameters: none. Return: 0; prints the absolute root path.
# Example: root="$(_mdtk_doctor_root)"
# ------------------------------------------------------------
_mdtk_doctor_root() {
    local source_file="${functions_source[_mdtk_doctor_root]}"
    printf '%s\n' "${source_file:A:h:h:h}"
}

# ------------------------------------------------------------
# _mdtk_doctor_result
# ------------------------------------------------------------
# Description: Print one diagnostic status line through the shared formatter.
# Parameters: $1 level; $2 check name; $3 detail. Return: formatter status.
# Example: _mdtk_doctor_result "success" "Zsh" "5.9"
# ------------------------------------------------------------
_mdtk_doctor_result() {
    local level="$1"
    local check_name="$2"
    local detail="$3"
    mdtk_utils_color_log "$level" "${check_name}: ${detail}"
}

# ------------------------------------------------------------
# _mdtk_doctor_check_platform
# ------------------------------------------------------------
# Description: Verify that MDTK is running on its supported macOS platform.
# Parameters: none. Return: 0 supported; 1 unsupported.
# Example: _mdtk_doctor_check_platform
# ------------------------------------------------------------
_mdtk_doctor_check_platform() {
    local system
    system="$(uname -s 2>/dev/null)" || system="unknown"
    if [[ "$system" == "Darwin" ]]; then
        _mdtk_doctor_result "success" "macOS" "available"
        return 0
    fi
    _mdtk_doctor_result "error" "macOS" "required; detected ${system}"
    return 1
}

# ------------------------------------------------------------
# _mdtk_doctor_check_zsh
# ------------------------------------------------------------
# Description: Verify the supported Zsh 5.x-or-newer runtime.
# Parameters: none. Return: 0 supported; 1 unsupported/unavailable.
# Example: _mdtk_doctor_check_zsh
# ------------------------------------------------------------
_mdtk_doctor_check_zsh() {
    local version="${ZSH_VERSION:-}"
    local major="${version%%.*}"
    if [[ -n "$version" && "$major" == <-> ]] && (( major >= 5 )); then
        _mdtk_doctor_result "success" "Zsh" "$version"
        return 0
    fi
    _mdtk_doctor_result "error" "Zsh" "version 5 or newer is required"
    return 1
}

# ------------------------------------------------------------
# _mdtk_doctor_check_homebrew
# ------------------------------------------------------------
# Description: Verify Homebrew is discoverable and answers a local query.
# Parameters: none. Return: 0 healthy; 1 missing/broken.
# Example: _mdtk_doctor_check_homebrew
# ------------------------------------------------------------
_mdtk_doctor_check_homebrew() {
    if ! mdtk_backend_homebrew_available; then
        _mdtk_doctor_result "error" "Homebrew" "not found; install it from https://brew.sh"
        return 1
    fi
    local prefix
    prefix="$(brew --prefix 2>/dev/null)" || prefix=""
    if [[ -z "$prefix" ]]; then
        _mdtk_doctor_result "error" "Homebrew" "could not run; try 'brew doctor'"
        return 1
    fi
    _mdtk_doctor_result "success" "Homebrew" "$prefix"
    return 0
}

# ------------------------------------------------------------
# _mdtk_doctor_check_executable
# ------------------------------------------------------------
# Description: Verify `mdtk` on PATH resolves to this checkout's entry point.
# Parameters: none. Return: 0 current; 1 missing or points elsewhere.
# Example: _mdtk_doctor_check_executable
# ------------------------------------------------------------
_mdtk_doctor_check_executable() {
    local executable="${commands[mdtk]:-}"
    local expected="$(_mdtk_doctor_root)/bin/mdtk"
    if [[ -z "$executable" ]]; then
        _mdtk_doctor_result "error" "MDTK command" "not on PATH; run './scripts/dev-install.zsh'"
        return 1
    fi
    if [[ "${executable:A}" != "${expected:A}" ]]; then
        _mdtk_doctor_result "error" "MDTK command" "points to ${executable:A}; reinstall this checkout"
        return 1
    fi
    _mdtk_doctor_result "success" "MDTK command" "${executable:A}"
    return 0
}

# ------------------------------------------------------------
# _mdtk_doctor_check_hook
# ------------------------------------------------------------
# Description: Check whether .zshrc sources this checkout's shell integration.
# Parameters: none. Return: 0 present; 2 warning when absent.
# Example: _mdtk_doctor_check_hook
# ------------------------------------------------------------
_mdtk_doctor_check_hook() {
    local zshrc="${HOME:-/tmp}/.zshrc"
    local hook="source \"$(_mdtk_doctor_root)/scripts/mdtk.zsh\""
    if [[ -f "$zshrc" ]] && grep -qxF "$hook" "$zshrc" 2>/dev/null; then
        _mdtk_doctor_result "success" "Shell hook" "$zshrc"
        return 0
    fi
    _mdtk_doctor_result "warning" "Shell hook" "not loaded; run './scripts/dev-install.zsh'"
    return 2
}

# ------------------------------------------------------------
# _mdtk_doctor_check_index
# ------------------------------------------------------------
# Description: Verify the offline index is readable, non-empty, well formed,
#   uniquely byte-sorted, and within the supported 8 MiB safety limit.
# Parameters: none. Return: 0 valid; 2 warning when missing/invalid.
# Example: _mdtk_doctor_check_index
# ------------------------------------------------------------
_mdtk_doctor_check_index() {
    local index_file
    index_file="$(mdtk_utils_path_cache_file "command_index")"
    local size
    size=$(/usr/bin/stat -f '%z' "$index_file" 2>/dev/null) || size="0"
    if [[ ! -f "$index_file" || ! -r "$index_file" || "$size" != <-> ]] ||
        (( size == 0 || size > 8388608 )); then
        _mdtk_doctor_result "warning" "Command index" "missing or unreadable; run 'mdtk index build'"
        return 2
    fi
    if LC_ALL=C grep -Evq '^[^=[:cntrl:]]+=[A-Za-z0-9@+_.-]+$' "$index_file" 2>/dev/null ||
        ! LC_ALL=C sort -cu "$index_file" >/dev/null 2>&1; then
        _mdtk_doctor_result "warning" "Command index" "invalid; run 'mdtk index build'"
        return 2
    fi
    local entries
    entries="$(wc -l < "$index_file" | tr -d '[:space:]')"
    _mdtk_doctor_result "success" "Command index" "${entries} entries"
    return 0
}

# ------------------------------------------------------------
# _mdtk_doctor_writable_ancestor
# ------------------------------------------------------------
# Description: Find whether a path or its nearest existing parent is writable.
# Parameters: $1 path. Return: 0 writable; 1 not writable/unresolvable.
# Example: _mdtk_doctor_writable_ancestor "$HOME/.cache/mdtk"
# ------------------------------------------------------------
_mdtk_doctor_writable_ancestor() {
    local candidate="${1:A}"
    while [[ ! -e "$candidate" ]]; do
        [[ "$candidate" == "/" ]] && break
        candidate="${candidate:h}"
    done
    [[ -d "$candidate" && -w "$candidate" ]]
}

# ------------------------------------------------------------
# _mdtk_doctor_check_user_paths
# ------------------------------------------------------------
# Description: Verify cache and configuration locations can hold MDTK data.
# Parameters: none. Return: 0 writable; 1 either location is not writable.
# Example: _mdtk_doctor_check_user_paths
# ------------------------------------------------------------
_mdtk_doctor_check_user_paths() {
    local cache_dir="$(mdtk_utils_path_cache_dir)"
    local config_dir="${$(mdtk_utils_path_config):h}"
    local failed=0
    if _mdtk_doctor_writable_ancestor "$cache_dir"; then
        _mdtk_doctor_result "success" "Cache path" "$cache_dir"
    else
        _mdtk_doctor_result "error" "Cache path" "not writable: ${cache_dir}"
        failed=1
    fi
    if _mdtk_doctor_writable_ancestor "$config_dir"; then
        _mdtk_doctor_result "success" "Config path" "$config_dir"
    else
        _mdtk_doctor_result "error" "Config path" "not writable: ${config_dir}"
        failed=1
    fi
    return "$failed"
}

# ------------------------------------------------------------
# _mdtk_doctor_usage
# ------------------------------------------------------------
# Description: Print Doctor CLI usage.
# Parameters: none. Return: 0.
# Example: _mdtk_doctor_usage
# ------------------------------------------------------------
_mdtk_doctor_usage() {
    cat <<'EOF'
Usage: mdtk doctor [help]

Run read-only checks for the local MDTK environment.
EOF
}

# ------------------------------------------------------------
# mdtk_doctor_dispatch
# ------------------------------------------------------------
# Description: Parse Doctor arguments, run all checks, and summarize health.
# Parameters: $@ empty, help, -h, or --help.
# Return: 0 healthy/help; 1 required failure or invalid arguments.
# Example: mdtk doctor
# ------------------------------------------------------------
mdtk_doctor_dispatch() {
    local command="${1:-}"
    if (( $# > 1 )); then
        mdtk_utils_color_log "error" "Usage: mdtk doctor [help]" >&2
        return 1
    fi
    case "$command" in
        "") ;;
        help|-h|--help)
            _mdtk_doctor_usage
            return 0
            ;;
        *)
            mdtk_utils_color_log "error" "Unknown doctor option: ${command}" >&2
            mdtk_utils_color_log "info" "Run 'mdtk doctor help' for usage." >&2
            return 1
            ;;
    esac

    local failures=0
    local warnings=0
    _mdtk_doctor_check_platform || (( failures += 1 ))
    _mdtk_doctor_check_zsh || (( failures += 1 ))
    _mdtk_doctor_check_homebrew || (( failures += 1 ))
    _mdtk_doctor_check_executable || (( failures += 1 ))
    _mdtk_doctor_check_hook || (( warnings += 1 ))
    _mdtk_doctor_check_index || (( warnings += 1 ))
    _mdtk_doctor_check_user_paths || (( failures += 1 ))

    if (( failures > 0 )); then
        mdtk_utils_color_log "error" "Doctor found ${failures} required problem(s) and ${warnings} warning(s)."
        return 1
    fi
    if (( warnings > 0 )); then
        mdtk_utils_color_log "warning" "Doctor passed with ${warnings} warning(s)."
    else
        mdtk_utils_color_log "success" "Doctor found no problems."
    fi
    return 0
}
