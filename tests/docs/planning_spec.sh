# shellcheck shell=sh
# ============================================================
# File:    tests/docs/planning_spec.sh
# Purpose: Keep authoritative planning metadata synchronized.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   Guards shipped and planned milestones across PRODUCT, ROADMAP, and TASK so
#   the authoritative specs cannot silently drift apart again.
#
# Run
#   make testone FILE=tests/docs/planning_spec.sh
# ============================================================

Describe 'planning metadata'
    It 'records Homebrew as shipped in v0.1'
        When run grep -F 'Homebrew  (v0.1)' .ai/PRODUCT.md
        The status should be successful
        The output should include 'Homebrew  (v0.1)'
    End

    It 'places Doctor in roadmap v0.2'
        When run sh -c 'sed -n "/^## v0.2/,/^## v0.3/p" .ai/ROADMAP.md | grep -F -- "- Doctor"'
        The status should be successful
        The output should include '- Doctor'
    End

    It 'places native Zsh completion in roadmap v0.2'
        When run sh -c 'sed -n "/^## v0.2/,/^## v0.3/p" .ai/ROADMAP.md | grep -F -- "- Native Zsh command completion"'
        The status should be successful
        The output should include '- Native Zsh command completion'
    End

    It 'records Plugin in the shipped v0.3 milestone'
        When run grep -F '## v0.3 — Extensibility (shipped)' .ai/ROADMAP.md
        The status should be successful
        The output should include '(shipped)'
    End

    It 'keeps Plugin as the v0.3 milestone item'
        When run sh -c 'sed -n "/^## v0.3/,/^## v0.4/p" .ai/ROADMAP.md | grep -F -- "- Plugin"'
        The status should be successful
        The output should include '- Plugin'
    End

    It 'records Plugin capabilities as shipped in product metadata'
        When run sh -c 'sed -n "/^### Shipped in v0.3.0/,/^### Planned/p" .ai/PRODUCT.md | grep -F -- "- Explicit, lazy plugin execution"'
        The status should be successful
        The output should include '- Explicit, lazy plugin execution'
    End

    It 'records package backends in the shipped v0.4 milestone'
        When run grep -F '## v0.4 — More backends (shipped)' .ai/ROADMAP.md
        The status should be successful
        The output should include '(shipped)'
    End

    It 'records backend selection as shipped product behavior'
        When run sh -c 'sed -n "/^### Shipped in v0.4.0/,/^### Planned/p" .ai/PRODUCT.md | grep -F -- "- Explicit backend selection for package search and install recommendations"'
        The status should be successful
        The output should include 'Explicit backend selection'
    End

    It 'records the production release as shipped in the roadmap'
        When run grep -F '## v1.0 — Production release (shipped)' .ai/ROADMAP.md
        The status should be successful
        The output should include '(shipped)'
    End

    It 'records the release-readiness gate as shipped product behavior'
        When run sh -c 'sed -n "/^### Shipped in v1.0.0/,/^### Planned/p" .ai/PRODUCT.md | grep -F -- "- Repeatable offline production release-readiness gate"'
        The status should be successful
        The output should include 'release-readiness gate'
    End

    It 'records the multi-backend offline index as shipped in v1.1'
        When run grep -F '## v1.1 — Multi-backend offline command index (shipped)' .ai/ROADMAP.md
        The output should include '(shipped)'
        The status should be successful
    End

    It 'records repository catalogs and offline multi-backend CNF in product metadata'
        When run sh -c 'sed -n "/^### Shipped in v1.1.0/,/^### Planned/p" .ai/PRODUCT.md | grep -F -- "Repository-maintained \`popular\` CLI catalog"'
        The output should include 'Repository-maintained `popular` CLI catalogs'
        The status should be successful
    End

    It 'records the agreed v1.1 capacity and query order'
        When run sh -c 'sed -n "/^### Shipped in v1.1.0/,/^### Planned/p" .ai/PRODUCT.md'
        The output should include '80 MiB'
        The output should include 'Homebrew, pip, npm, Cargo, and conda order'
        The status should be successful
    End

    It 'records per-backend failure isolation and local-only statistics'
        When run sh -c 'sed -n "/^### Shipped in v1.1.0/,/^### Planned/p" .ai/PRODUCT.md'
        The output should include 'per-backend failure isolation'
        The output should include 'no statistics are uploaded'
        The status should be successful
    End

    It 'records planning issue 074 in the closed backlog'
        When run sh -c 'sed -n "/^## Closed/,\$p" .ai/TASK.md | grep -F "#074 v1.1 multi-backend offline-index planning — **closed**"'
        The output should include '#074'
        The output should include '**closed**'
        The status should be successful
    End

    It 'records the v1.1 release as the closed current issue'
        When run grep -F '### #084 Release version 1.1.0 — **closed**' .ai/TASK.md
        The output should include '#084 Release version 1.1.0'
        The output should include '**closed**'
        The status should be successful
    End

    It 'leaves no later milestone queued'
        When run grep -F '_No later milestone is scheduled._' .ai/TASK.md
        The output should include 'No later milestone is scheduled.'
        The status should be successful
    End

    It 'keeps future backends explicitly unscheduled after v1.1'
        When run grep -F 'docker    (future, post-v1.1)' .ai/PRODUCT.md
        The output should include 'post-v1.1'
        The status should be successful
    End

    It 'records the v1.1.0 release date in the changelog'
        When run grep -F '## [1.1.0] - 2026-08-05' CHANGELOG.md
        The output should include '[1.1.0]'
        The status should be successful
    End

    It 'records the Leju Gym mappings as shipped in v1.1.1'
        When run sh -c 'sed -n "/^### Shipped in v1.1.1/,/^### Planned/p" .ai/PRODUCT.md'
        The output should include '`gym` and `gym-mcp`'
        The status should be successful
    End

    It 'records the v1.1.1 patch release date in the changelog'
        When run grep -F '## [1.1.1] - 2026-08-05' CHANGELOG.md
        The output should include '[1.1.1]'
        The status should be successful
    End

    It 'records Doctor as a closed v0.2 issue'
        When run grep -F '#012 Doctor — `src/doctor/doctor.zsh` (v0.2 per ROADMAP) — **closed**' .ai/TASK.md
        The status should be successful
        The output should include '**closed**'
    End
End
