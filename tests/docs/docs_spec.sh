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

    It 'documents explicit refresh and per-backend failure isolation'
        When run grep -F 'mdtk index refresh --backend npm' README.md
        The status should be successful
        The output should include 'mdtk index refresh --backend npm'
    End

    It 'documents manifest states in the refresh architecture'
        When run grep -F 'rebuilt/failed/not-selected states' docs/architecture.md
        The status should be successful
        The output should include 'rebuilt/failed/not-selected states'
    End

    It 'documents all-match offline command-not-found behavior'
        When run grep -F '展示全部命中及对应安装命令' README.md
        The status should be successful
        The output should include '展示全部命中及对应安装命令'
    End

    It 'documents that optional package tools are unnecessary for CNF lookup'
        When run grep -F 'popular-CLI command indexes are queried locally' docs/faq.md
        The status should be successful
        The output should include 'queried locally'
    End

    It 'documents local aggregate statistics privacy and the hit-rate command'
        When run grep -F 'mdtk index stats' README.md
        The status should be successful
        The output should include 'mdtk index stats'
    End

    It 'documents that aggregate events never contain command text'
        When run grep -F 'command text and arguments' docs/architecture.md
        The status should be successful
        The output should include 'command text and arguments'
    End

    It 'documents that detailed miss tracking is disabled by default'
        When run grep -F '命令级 miss 记录默认关闭' README.md
        The status should be successful
        The output should include '默认关闭'
    End

    It 'documents private bounded detailed miss storage'
        When run grep -F '最大 256 KiB' README.md
        The status should be successful
        The output should include '256 KiB'
    End

    It 'documents reset without changing the opt-in choice'
        When run grep -F "reset removes history without silently changing" docs/architecture.md
        The status should be successful
        The output should include 'reset removes history'
    End

    It 'documents static Index argument completion without external calls'
        When run grep -F 'tracking action 和报告 limit' README.md
        The status should be successful
        The output should include 'tracking action 和报告 limit'
    End

    It 'does not hardcode the obsolete test count'
        When run sh -c '! grep -R "98 examples\|98 个 example" README.md docs/development.md'
        The status should be successful
    End
End
