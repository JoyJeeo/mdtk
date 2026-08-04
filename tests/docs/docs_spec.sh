# shellcheck shell=sh
# ============================================================
# File:    tests/docs/docs_spec.sh
# Purpose: Guard current user-facing documentation facts.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   Prevents known stale runtime, module-status, and test-count claims
#   from returning to the maintained README and docs pages.
#
# Run
#   make testone FILE=tests/docs/docs_spec.sh
# ============================================================

Describe 'maintained documentation'
    It 'does not require conda for end users'
        When run grep -F 'End users do not need conda.' docs/faq.md
        The status should be successful
        The output should include 'End users do not need conda.'
    End

    It 'describes every scheduled backend as implemented'
        When run grep -F 'Homebrew, pip, cargo, conda, and npm are implemented' docs/architecture.md
        The status should be successful
        The output should include 'Homebrew, pip, cargo, conda, and npm are implemented'
    End

    It 'does not hardcode the obsolete test count'
        When run sh -c '! grep -R "98 examples\|98 个 example" README.md docs/development.md'
        The status should be successful
    End
End
