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

    It 'documents isolated offline index lookup and its capacity boundary'
        When run grep -F '五个索引的容量上限合计为 80 MiB' README.md
        The status should be successful
        The output should include '80 MiB'
    End

    It 'documents that all-backend index lookup stays offline'
        When run grep -F 'without calling a backend or the network' docs/architecture.md
        The status should be successful
        The output should include 'without calling a backend or the network'
    End

    It 'documents the maintained popular catalog format'
        When run grep -F 'rank|package|command command-alias' catalogs/README.md
        The status should be successful
        The output should include 'rank|package|command command-alias'
    End

    It 'does not hardcode the obsolete test count'
        When run sh -c '! grep -R "98 examples\|98 个 example" README.md docs/development.md'
        The status should be successful
    End
End
