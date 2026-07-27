# shellcheck shell=sh
# ============================================================
# File:    tests/docs/planning_spec.sh
# Purpose: Keep authoritative planning metadata synchronized.
# Author:  MDTK Team
# Date:    2026-07-28
# ============================================================
#
# Description
#   Guards the shipped Homebrew milestone and the next Doctor milestone
#   across PRODUCT, ROADMAP, and TASK so the authoritative specs cannot
#   silently drift apart again.
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

    It 'labels the queued Doctor issue as v0.2'
        When run grep -F '#012 Doctor — `src/doctor/doctor.zsh` (v0.2 per ROADMAP' .ai/TASK.md
        The status should be successful
        The output should include 'v0.2 per ROADMAP'
    End
End
