#!/usr/bin/env zsh
# ============================================================
# File:    src/install/install.zsh
# Purpose: Recommend package installation through a selected backend.
# Author:  MDTK Team
# Date:    2026-08-04
# ============================================================
#
# Description
#   Resolves a command through Homebrew (default), pip, cargo, conda, or npm
#   and prints a backend-appropriate command. It never installs software.
#   Routing uses fixed cases and calls only leaf backends.
#
# Parameters (mdtk_install_dispatch)
#   --backend <name>  homebrew (default), pip, cargo, conda, or npm.
#   <command>         command/package name to resolve.
#
# Return
#   0 recommendation or friendly miss; 1 usage/tool/backend failure.
#
# Example
#   mdtk install rg
#   mdtk install --backend npm typescript
# ============================================================

local _mdtk_install_src_root="${${(%):-%x}:A:h:h}"
source "${_mdtk_install_src_root}/backends/homebrew.zsh"
source "${_mdtk_install_src_root}/backends/pip.zsh"
source "${_mdtk_install_src_root}/backends/cargo.zsh"
source "${_mdtk_install_src_root}/backends/conda.zsh"
source "${_mdtk_install_src_root}/backends/npm.zsh"
source "${_mdtk_install_src_root}/utils/color.zsh"
unset _mdtk_install_src_root

# Description: Check availability for one validated backend.
# Parameters: $1 backend. Return: backend availability; 1 unknown.
# Example: _mdtk_install_backend_available "npm"
_mdtk_install_backend_available() {
    case "$1" in
        homebrew) mdtk_backend_homebrew_available ;;
        pip)      mdtk_backend_pip_available ;;
        cargo)    mdtk_backend_cargo_available ;;
        conda)    mdtk_backend_conda_available ;;
        npm)      mdtk_backend_npm_available ;;
        *)        return 1 ;;
    esac
}

# Description: Resolve a command through one validated backend.
# Parameters: $1 backend; $2 command. Return: backend provides status.
# Example: _mdtk_install_backend_provides "cargo" "ripgrep"
_mdtk_install_backend_provides() {
    local backend="$1" command_name="$2"
    case "$backend" in
        homebrew) mdtk_backend_homebrew_provides "$command_name" ;;
        pip)      mdtk_backend_pip_provides "$command_name" ;;
        cargo)    mdtk_backend_cargo_provides "$command_name" ;;
        conda)    mdtk_backend_conda_provides "$command_name" ;;
        npm)      mdtk_backend_npm_provides "$command_name" ;;
        *)        return 1 ;;
    esac
}

# Description: Print the install command appropriate for a backend/package.
# Parameters: $1 backend; $2 package. Return: 0 printed; 1 unknown backend.
# Example: _mdtk_install_run_line "npm" "typescript"
_mdtk_install_run_line() {
    local backend="$1" package="$2"
    case "$backend" in
        homebrew) echo "brew install ${package}" ;;
        pip)      echo "pip install ${package}" ;;
        cargo)    echo "cargo install ${package}" ;;
        conda)    echo "conda install ${package}" ;;
        npm)      echo "npm install --global ${package}" ;;
        *)        return 1 ;;
    esac
}

# Description: Print a recommendation or friendly miss for one backend.
# Parameters: $1 command; $2 optional backend (default homebrew).
# Return: 0 recommendation/miss; 1 invalid/unavailable/backend failure.
# Example: mdtk_install_recommend "typescript" "npm"
mdtk_install_recommend() {
    local command_name="${1:-}" backend="${2:-homebrew}"
    [[ -n "$command_name" ]] || return 1
    case "$backend" in
        homebrew|pip|cargo|conda|npm) ;;
        *)
            mdtk_utils_color_log "error" "Unknown package backend: ${backend}" >&2
            return 1
            ;;
    esac
    if ! _mdtk_install_backend_available "$backend"; then
        if [[ "$backend" == "homebrew" ]]; then
            mdtk_utils_color_log "error" "Homebrew is not installed. mdtk install needs Homebrew." >&2
        else
            mdtk_utils_color_log "error" "Package backend is not available: ${backend}" >&2
        fi
        return 1
    fi

    local package
    package=$(_mdtk_install_backend_provides "$backend" "$command_name")
    local provides_status=$?
    if (( provides_status == 0 )) && [[ -n "$package" ]]; then
        if [[ "$backend" == "homebrew" ]]; then
            mdtk_utils_color_log "success" "Found: the \"${command_name}\" command is provided by the \"${package}\" formula."
        else
            mdtk_utils_color_log "success" "Found: the \"${command_name}\" command matches the \"${package}\" package in ${backend}."
        fi
        mdtk_utils_color_log "info" "Run: $(_mdtk_install_run_line "$backend" "$package")"
        return 0
    fi
    if [[ "$backend" == "homebrew" ]]; then
        mdtk_utils_color_log "warning" "No Homebrew formula found that provides \"${command_name}\"."
        mdtk_utils_color_log "info" "Try: mdtk search ${command_name}"
    else
        mdtk_utils_color_log "warning" "No ${backend} package found for \"${command_name}\"."
        mdtk_utils_color_log "info" "Try: mdtk search --backend ${backend} ${command_name}"
    fi
    return 0
}

# Description: Print Install CLI usage.
# Parameters: none. Return: 0.
# Example: _mdtk_install_usage
_mdtk_install_usage() {
    cat <<'EOF'
Usage: mdtk install [--backend <name>] <command>

Print an install recommendation without installing software.
Backends: homebrew (default), pip, cargo, conda, npm.

Examples:
  mdtk install rg
  mdtk install --backend npm typescript
EOF
}

# Description: Parse Install CLI options and print one recommendation.
# Parameters: documented in file header. Return: 0 success/help; 1 error.
# Example: mdtk_install_dispatch --backend pip httpie
mdtk_install_dispatch() {
    local backend="homebrew" command_name=""
    while (( $# )); do
        case "$1" in
            --backend)
                shift
                if [[ -z "${1:-}" ]]; then
                    mdtk_utils_color_log "error" "Option --backend requires a name." >&2
                    return 1
                fi
                backend="$1"
                ;;
            help|--help|-h)
                _mdtk_install_usage
                return 0
                ;;
            -*)
                mdtk_utils_color_log "error" "Unknown install option: $1" >&2
                return 1
                ;;
            *)
                if [[ -n "$command_name" ]]; then
                    mdtk_utils_color_log "error" "Install accepts one command." >&2
                    return 1
                fi
                command_name="$1"
                ;;
        esac
        shift
    done
    if [[ -z "$command_name" ]]; then
        _mdtk_install_usage
        return 1
    fi
    mdtk_install_recommend "$command_name" "$backend"
}
