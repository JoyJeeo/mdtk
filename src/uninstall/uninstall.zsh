#!/usr/bin/env zsh
# ============================================================
# File:    src/uninstall/uninstall.zsh
# Purpose: Safely remove an MDTK installation and its managed data.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   Implements `mdtk uninstall`. Removes command symlinks that point to
#   this MDTK installation, its exact shell-hook block, cache data, and
#   optionally configuration. A source tree is removed only when it is
#   the expected XDG data path and contains MDTK's managed-install marker;
#   ordinary repository checkouts are never deleted.
#
# Parameters (mdtk_uninstall_dispatch)
#   --yes          Skip confirmation.
#   --keep-config  Preserve the MDTK configuration directory.
#   --dry-run      Print actions without changing files.
#   --help         Show usage.
#
# Return
#   0  uninstalled, cancelled, or dry-run completed.
#   1  invalid arguments or an I/O failure.
#
# Example
#   mdtk uninstall
#   mdtk uninstall --yes --keep-config
#   mdtk uninstall --dry-run
# ============================================================

typeset -r MDTK_UNINSTALL_MARKER_CONTENT="managed-by=mdtk-bootstrap-v1"

# Description: Resolve the running MDTK source root.
# Parameters: none. Return: 0; prints an absolute path.
# Example: root="$(_mdtk_uninstall_root)"
_mdtk_uninstall_root() {
    if [[ -n "${MDTK_UNINSTALL_ROOT:-}" ]]; then
        echo "${MDTK_UNINSTALL_ROOT:A}"
        return 0
    fi
    local self
    self="${(%):-%x}"
    echo "${self:A:h:h:h}"
}

# Description: Resolve the XDG-aware MDTK cache directory.
# Parameters: none. Return: 0; prints an absolute path.
# Example: _mdtk_uninstall_cache_dir
_mdtk_uninstall_cache_dir() {
    local base="${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}"
    echo "${base:A}/mdtk"
}

# Description: Resolve the XDG-aware MDTK configuration directory.
# Parameters: none. Return: 0; prints an absolute path.
# Example: _mdtk_uninstall_config_dir
_mdtk_uninstall_config_dir() {
    local base="${XDG_CONFIG_HOME:-${HOME:-/tmp}/.config}"
    echo "${base:A}/mdtk"
}

# Description: Resolve the expected managed-install root.
# Parameters: none. Return: 0; prints an absolute path.
# Example: _mdtk_uninstall_data_root
_mdtk_uninstall_data_root() {
    local base="${XDG_DATA_HOME:-${HOME:-/tmp}/.local/share}"
    echo "${base:A}/mdtk"
}

# Description: Validate a destructive directory target.
# Parameters: $1 target. Return: 0 only for a non-root path named mdtk.
# Example: _mdtk_uninstall_safe_mdtk_dir "$cache_dir"
_mdtk_uninstall_safe_mdtk_dir() {
    local target="${1:-}"
    [[ -n "$target" ]] || return 1
    [[ "$target" != "/" ]] || return 1
    [[ "$target" != "${HOME:-}" ]] || return 1
    [[ "${target:t}" == "mdtk" ]] || return 1
    local parent="${target:h}"
    [[ "$parent" != "/" ]] || return 1
    [[ "$parent" != "${HOME:-}" ]] || return 1
    return 0
}

# Description: Print candidate command-link paths, one per line.
# Parameters: none. Return: 0.
# Example: _mdtk_uninstall_link_candidates
_mdtk_uninstall_link_candidates() {
    local dirs="${MDTK_UNINSTALL_BIN_DIRS:-/usr/local/bin:${HOME:-/tmp}/.local/bin}"
    local dir
    for dir in ${(s/:/)dirs}; do
        [[ -n "$dir" ]] && echo "${dir:A}/mdtk"
    done
    local active="${commands[mdtk]:-}"
    # Keep the link path itself; :A would resolve it to the target.
    [[ -n "$active" ]] && echo "${active:a}"
}

# Description: Remove only symlinks targeting this root's bin/mdtk.
# Parameters: $1 dry_run (0/1). Return: 0.
# Example: _mdtk_uninstall_remove_links 1
_mdtk_uninstall_remove_links() {
    local dry_run="$1"
    local root target link resolved
    root="$(_mdtk_uninstall_root)"
    target="${root}/bin/mdtk"
    local seen=""
    for link in "${(@f)$(_mdtk_uninstall_link_candidates)}"; do
        [[ -n "$link" && -L "$link" ]] || continue
        [[ ":${seen}:" == *":${link}:"* ]] && continue
        seen="${seen}:${link}"
        resolved="${link:A}"
        [[ "$resolved" == "${target:A}" ]] || continue
        echo "Remove command link: ${link}"
        (( dry_run )) || rm -f -- "$link"
    done
    return 0
}

# Description: Remove this installation's exact hook and marker comment.
# Parameters: $1 dry_run (0/1). Return: 0 success; 1 I/O failure.
# Example: _mdtk_uninstall_remove_hook 0
_mdtk_uninstall_remove_hook() {
    local dry_run="$1"
    local zshrc="${HOME:-/tmp}/.zshrc"
    [[ -f "$zshrc" ]] || return 0

    local root hook line pending="" found=0
    root="$(_mdtk_uninstall_root)"
    hook="source \"${root}/scripts/mdtk.zsh\""
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "# Added by mdtk installer." ]]; then
            pending="$line"
            continue
        fi
        if [[ "$line" == "$hook" ]]; then
            pending=""
            found=1
            continue
        fi
        [[ -n "$pending" ]] && pending=""
    done < "$zshrc"
    (( found )) || return 0

    echo "Remove shell hook: ${zshrc}"
    (( dry_run )) && return 0

    local tmp="${zshrc}.mdtk-uninstall.$$"
    pending=""
    {
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == "# Added by mdtk installer." ]]; then
                pending="$line"
                continue
            fi
            if [[ "$line" == "$hook" ]]; then
                pending=""
                continue
            fi
            if [[ -n "$pending" ]]; then
                echo "$pending"
                pending=""
            fi
            echo "$line"
        done < "$zshrc"
        [[ -n "$pending" ]] && echo "$pending"
    } > "$tmp" || { rm -f -- "$tmp"; return 1; }
    cp "$zshrc" "${zshrc}.mdtk-uninstall-backup.$(date +%s)" || {
        rm -f -- "$tmp"
        return 1
    }
    mv -f -- "$tmp" "$zshrc"
    return 0
}

# Description: Safely remove one validated MDTK data directory.
# Parameters: $1 label, $2 path, $3 dry_run. Return: 0/1.
# Example: _mdtk_uninstall_remove_dir "cache" "$dir" 0
_mdtk_uninstall_remove_dir() {
    local label="$1"
    local target="$2"
    local dry_run="$3"
    [[ -e "$target" ]] || return 0
    if ! _mdtk_uninstall_safe_mdtk_dir "$target"; then
        echo "Refusing unsafe ${label} path: ${target}" >&2
        return 1
    fi
    echo "Remove ${label}: ${target}"
    (( dry_run )) || rm -rf -- "$target"
}

# Description: Validate a marked managed root before any destructive work.
# Parameters: none. Return: 0 safe/not-managed; 1 unsafe marker/path.
# Example: _mdtk_uninstall_validate_managed_root
_mdtk_uninstall_validate_managed_root() {
    local root expected marker content
    root="$(_mdtk_uninstall_root)"
    expected="$(_mdtk_uninstall_data_root)"
    marker="${root}/.mdtk-managed-install"
    [[ -f "$marker" ]] || return 0
    content="$(<"$marker")"
    if [[ "${root:A}" != "${expected:A}" || "$content" != "$MDTK_UNINSTALL_MARKER_CONTENT" ]]; then
        echo "Refusing unsafe managed install path: ${root}" >&2
        return 1
    fi
    return 0
}

# Description: Remove a marker-validated XDG managed install root.
# Parameters: $1 dry_run. Return: 0/1.
# Example: _mdtk_uninstall_remove_managed_root 0
_mdtk_uninstall_remove_managed_root() {
    local dry_run="$1"
    local root marker
    root="$(_mdtk_uninstall_root)"
    marker="${root}/.mdtk-managed-install"
    [[ -f "$marker" ]] || return 0
    _mdtk_uninstall_validate_managed_root || return 1
    echo "Remove managed installation: ${root}"
    (( dry_run )) || rm -rf -- "$root"
    return 0
}

# Description: Print CLI usage. Parameters: none. Return: 0.
# Example: _mdtk_uninstall_usage
_mdtk_uninstall_usage() {
    cat <<'EOF'
Usage: mdtk uninstall [options]

Options:
  --yes          Uninstall without confirmation.
  --keep-config  Keep the MDTK configuration directory.
  --dry-run      Show what would be removed without changing files.
  --help         Show this message.

Examples:
  mdtk uninstall
  mdtk uninstall --yes --keep-config
  mdtk uninstall --dry-run
EOF
}

# Description: Parse options, confirm, and uninstall managed MDTK files.
# Parameters: documented in the file header. Return: 0 success; 1 error.
# Example: mdtk_uninstall_dispatch --yes
mdtk_uninstall_dispatch() {
    local assume_yes=0 keep_config=0 dry_run=0 arg
    while (( $# )); do
        arg="$1"
        case "$arg" in
            --yes) assume_yes=1 ;;
            --keep-config) keep_config=1 ;;
            --dry-run) dry_run=1 ;;
            --help|-h)
                _mdtk_uninstall_usage
                return 0
                ;;
            *)
                echo "Unknown uninstall option: ${arg}" >&2
                _mdtk_uninstall_usage
                return 1
                ;;
        esac
        shift
    done

    if (( ! assume_yes && ! dry_run )); then
        local answer=""
        printf 'Remove MDTK from this user account? [y/N] '
        IFS= read -r answer
        case "${(L)answer}" in
            y|yes) ;;
            *)
                echo "Cancelled."
                return 0
                ;;
        esac
    fi

    # Preflight marker/path safety before changing any user files.
    _mdtk_uninstall_validate_managed_root || return 1

    (( dry_run )) && echo "Dry run: no files will be changed."
    _mdtk_uninstall_remove_links "$dry_run" || return 1
    _mdtk_uninstall_remove_hook "$dry_run" || return 1
    _mdtk_uninstall_remove_dir "cache" "$(_mdtk_uninstall_cache_dir)" "$dry_run" || return 1
    if (( ! keep_config )); then
        _mdtk_uninstall_remove_dir "configuration" "$(_mdtk_uninstall_config_dir)" "$dry_run" || return 1
    fi
    _mdtk_uninstall_remove_managed_root "$dry_run" || return 1
    (( dry_run )) || echo "MDTK was uninstalled."
    return 0
}
