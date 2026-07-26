# shellcheck shell=sh
# ============================================================
# File:    tests/backends/homebrew_spec.sh
# Purpose: Tests for the Homebrew backend (Issue #006).
# Author:  MDTK Team
# Date:    2026-07-26
# ============================================================
#
# Description
#   Tests for src/backends/homebrew.zsh. `brew` is mocked with a
#   shell function override inside the spec — no real network or
#   installs (`.ai/TESTING.md`). Covers available, search,
#   provides (same-name + alias), install, missing brew, empty input.
#
# Run
#   make test
# ============================================================

MDTK_ROOT="${SHELLSPEC_PROJECT_ROOT}"
. "${MDTK_ROOT}/src/backends/homebrew.zsh"

# A fake `brew` used to drive search/provides/install deterministically.
# $1 is the brew subcommand (search/info/install); subsequent args follow.
_mdt_fake_brew_info() {
    # Called as: brew info --json=v1 <name>; so $3 is the name.
    local name="$3"
    case "$name" in
        ripgrep)
            # Has alias "rg".
            echo '[{"name":"ripgrep","aliases":["rg"]}]'
            ;;
        rg)
            # No formula literally named "rg" — simulate brew info failing.
            echo "Error: No available formula" >&2
            return 1
            ;;
        *)
            echo "[]"
            ;;
    esac
}

Describe 'mdtk backend homebrew'
    BeforeEach 'unfunction brew 2>/dev/null || true'

    Describe 'available'
        It 'reports available when brew is on PATH'
            # Provide a brew function so ${+commands[brew]} path... but
            # commands[] tracks real commands, not functions. Override
            # with a function and stub the available check via a PATH
            # shim instead.
            _mdtk_bin_dir="$(mktemp -d)"
            cat > "${_mdtk_bin_dir}/brew" <<'SH'
#!/usr/bin/env sh
echo "brew shim"
SH
            chmod +x "${_mdtk_bin_dir}/brew"
            export PATH="${_mdtk_bin_dir}:${PATH}"
            When call mdtk_backend_homebrew_available
            The status should be successful
            rm -rf "${_mdtk_bin_dir}"
        End
        It 'reports unavailable when brew is missing'
            export PATH="/usr/bin:/bin"
            When call mdtk_backend_homebrew_available
            The status should be failure
        End
    End

    Describe 'search'
        It 'prints formula names one per line'
            brew() { echo "ripgrep"; echo "ripgrep-all"; }
            When call mdtk_backend_homebrew_search "ripgrep"
            The output should include "ripgrep"
            The output should include "ripgrep-all"
            The status should be successful
        End
        It 'returns 1 when brew is missing'
            export PATH="/usr/bin:/bin"
            unfunction brew 2>/dev/null || true
            When call mdtk_backend_homebrew_search "ripgrep"
            The status should be failure
            The error should include "Homebrew is not installed"
        End
        It 'prints nothing for an empty query'
            brew() { echo "ripgrep"; echo "ripgrep-all"; }
            When call mdtk_backend_homebrew_search ""
            The output should be blank
            The status should be successful
        End
    End

    Describe 'provides'
        It 'finds a formula of the same name first'
            brew() {
                [[ "$1" == "info" ]] && _mdt_fake_brew_info "$@"
            }
            When call mdtk_backend_homebrew_provides "ripgrep"
            The output should equal "ripgrep"
            The status should be successful
        End
        It 'finds a formula via alias when no same-name formula'
            # search returns ripgrep; info --json=v1 ripgrep has alias rg.
            brew() {
                if [[ "$1" == "search" ]]; then
                    echo "ripgrep"
                elif [[ "$1" == "info" ]]; then
                    _mdt_fake_brew_info "$@"
                fi
            }
            When call mdtk_backend_homebrew_provides "rg"
            The output should include "ripgrep"
            The status should be successful
        End
        It 'returns nothing for an unknown command'
            brew() {
                if [[ "$1" == "search" ]]; then
                    echo "nope"
                elif [[ "$1" == "info" ]]; then
                    _mdt_fake_brew_info "$@"
                fi
            }
            When call mdtk_backend_homebrew_provides "definitely-not-a-cmd"
            The output should be blank
            The status should be successful
        End
    End

    Describe 'install'
        It 'forwards to brew install'
            # brew install <formula> — $1=install, $2=formula.
            brew() {
                echo "install called with: $2"
            }
            When call mdtk_backend_homebrew_install "ripgrep"
            The output should include "install called with: ripgrep"
            The status should be successful
        End
        It 'returns 1 for an empty formula'
            brew() { echo "should not be called"; }
            When call mdtk_backend_homebrew_install ""
            The status should be failure
        End
    End
End
