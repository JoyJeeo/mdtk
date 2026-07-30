#!/usr/bin/env zsh
# ============================================================
# File:    src/update/update.zsh
# Purpose: Update a managed MDTK installation through its installer.
# Author:  MDTK Team
# Date:    2026-07-29
# ============================================================
#
# Description
#   Updates only a marker-validated MDTK checkout at the XDG managed install
#   path. The module delegates ref validation, origin verification, checkout,
#   setup, and command-index rebuild to the checkout's top-level installer.
#   Ordinary source checkouts are intentionally refused.
#
# Parameters (mdtk_update_dispatch)
#   --ref <ref>  Update to an explicit branch or tag.
#   --coder      Update the development channel (`main`).
#   --help       Show usage.
#
# Return
#   0  update and setup completed, or help printed.
#   1  unsafe/unmanaged installation, bad arguments, or installer failure.
#
# Example
#   mdtk update
#   mdtk update --coder
# ============================================================

typeset -r MDTK_UPDATE_MARKER_CONTENT="managed-by=mdtk-bootstrap-v1"

# Description: Resolve the running checkout root.
# Parameters: none. Return: 0; prints an absolute path.
# Example: _mdtk_update_root
_mdtk_update_root() {
    if [[ -n "${MDTK_UPDATE_ROOT:-}" ]]; then
        echo "${MDTK_UPDATE_ROOT:A}"
        return 0
    fi
    local self="${(%):-%x}"
    echo "${self:A:h:h:h}"
}

# Description: Resolve the only path eligible for managed updates.
# Parameters: none. Return: 0; prints an absolute path.
# Example: _mdtk_update_expected_root
_mdtk_update_expected_root() {
    local base="${XDG_DATA_HOME:-${HOME:-/tmp}/.local/share}"
    echo "${base:A}/mdtk"
}

# Description: Verify the root path, marker, Git metadata, and installer.
# Parameters: $1 root. Return: 0 managed; 1 unsafe/unmanaged.
# Example: _mdtk_update_validate_root "$root"
_mdtk_update_validate_root() {
    local root="$1"
    local expected marker
    expected="$(_mdtk_update_expected_root)"
    marker="${root}/.mdtk-managed-install"
    [[ "${root:A}" == "${expected:A}" ]] || return 1
    [[ -d "${root}/.git" && -f "$marker" && -f "${root}/install.sh" ]] || return 1
    [[ "$(<"$marker")" == "$MDTK_UPDATE_MARKER_CONTENT" ]] || return 1
    return 0
}

# Description: Print update usage.
# Parameters: none. Return: 0.
# Example: _mdtk_update_usage
_mdtk_update_usage() {
    cat <<'EOF'
Usage: mdtk update [--ref <branch-or-tag>]

Options:
  --ref <ref>  Update to an explicit branch or tag.
  --coder      Update the development channel (`main`).
  --help       Show this message.

Examples:
  mdtk update
  mdtk update --coder
EOF
}

# Description: Parse options and update a validated managed installation.
# Parameters: documented in the file header. Return: 0 success; 1 error.
# Example: mdtk_update_dispatch --ref main
mdtk_update_dispatch() {
    local ref="" channel="stable"
    local coder_requested=0 ref_requested=0
    while (( $# )); do
        case "$1" in
            --ref)
                [[ "$coder_requested" == 0 ]] || { echo "Options --coder and --ref cannot be combined." >&2; return 1; }
                shift
                if [[ -z "${1:-}" ]]; then
                    echo "Option --ref requires a branch or tag." >&2
                    return 1
                fi
                ref="$1"
                ref_requested=1
                ;;
            --coder)
                [[ "$coder_requested" == 0 && "$ref_requested" == 0 ]] || { echo "Options --coder and --ref cannot be combined." >&2; return 1; }
                coder_requested=1
                channel="coder"
                ref="main"
                ;;
            --help|-h)
                _mdtk_update_usage
                return 0
                ;;
            *)
                echo "Unknown update option: $1" >&2
                _mdtk_update_usage
                return 1
                ;;
        esac
        shift
    done

    local root
    root="$(_mdtk_update_root)"
    if ! _mdtk_update_validate_root "$root"; then
        echo "Automatic update requires an MDTK-managed installation." >&2
        echo "Install with the remote installer, then try again." >&2
        return 1
    fi

    local repository_url
    repository_url="$(git -C "$root" remote get-url origin 2>/dev/null)" || {
        echo "Could not verify the managed installation origin." >&2
        return 1
    }
    [[ -n "$repository_url" ]] || {
        echo "Could not verify the managed installation origin." >&2
        return 1
    }

    echo "Updating MDTK channel: ${channel}${ref:+ (ref=${ref})}"
    MDTK_BOOTSTRAP_MANAGED_MODE=1 \
        MDTK_INSTALL_REPOSITORY_URL="$repository_url" \
        MDTK_INSTALL_CHANNEL="$channel" \
        MDTK_INSTALL_REF="$ref" \
        zsh "${root}/install.sh"
    return $?
}
