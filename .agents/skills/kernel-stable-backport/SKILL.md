---
name: kernel-stable-backport
description: Assess stable eligibility or adapt a verified upstream Linux kernel fix to specified older branches, with dependency analysis, semantic review and per-target validation. Use for stable requests and explicit backports, not routine feature development.
---

# Stable backports

Resolve the kernel root and follow AGENTS.md. Read the target tree's
Documentation/process/stable-kernel-rules.rst and backporting.rst completely,
plus relevant maintainer instructions. For security issues, read security-bugs.rst
before exposing details. Check current supported targets and stable status rather
than hard-coding a list of maintained releases.

## Establish eligibility and provenance

Record the actual upstream commit, affected versions, requested destination
branches, user-visible bug and reproducer. Verify whether an equivalent fix is
already in each target, stable queue or release, accounting for changed hashes.
An explicit downstream-only backport may be prepared as such; do not call it
eligible for Linux stable when upstream inclusion or other required criteria
are missing. Avoid speculative fixes, features and unrelated cleanup.

Distinguish adding stable guidance to an upstream submission, requesting an
already-mainlined commit be picked, and submitting an adjusted backport. Follow
the documented process for that case. For a stable request, check applicable newer
supported series as well so upgrading does not reintroduce the bug; report their
status without expanding the requested implementation scope silently.

## Adapt the fix, not just the diff

Work in a separate checkout for each destination. Understand the original failure
mechanism and inspect whole functions, callers and relevant history in both trees.
A clean cherry-pick does not prove semantic compatibility. Classify dependencies
as necessary for correctness or incidental refactoring; avoid importing large
cleanup chains simply to remove conflicts.

Compare API contracts, argument meanings, error labels, ownership, locking and
memory ordering, structure layout, configuration guards and initialization paths.
Follow renamed or split code: a change to one upstream helper may need equivalent
fixes at several older call sites. Document every adaptation and why it preserves
the upstream fix. Do not resolve conflicts solely by choosing ours or theirs.

Preserve upstream attribution and authentic trailers. Identify the upstream commit
using the documented stable format, explain backport-specific changes, and label
the destination version correctly. A local commit hash or cherry-pick annotation
alone is not the required upstream identity. Human DCO authorization and current
AI disclosure rules still apply; never manufacture sign-offs or review tags.

## Verify each destination

Build and test on the actual destination revision/configuration, including relevant
failure and regression paths. Compare the original and adapted functions, not
just conflict markers. Source application, compilation and runtime correctness
are separate checks. Use kernel-validation to record per-target evidence and
kernel-patch-submit for final patch/provenance/recipient audits.

Deliver a per-target summary of existing fix status, upstream identity, dependencies,
adaptations, validation and unresolved risks, plus exact patch artifacts when
preparation was requested. Follow a maintainer's concrete backport request when
present. Sending to stable or posting tags still requires authorization for that
external action; do not send automatically after a successful cherry-pick.
