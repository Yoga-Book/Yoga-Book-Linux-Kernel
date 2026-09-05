---
name: kernel-patch-submit
description: Prepare or audit a Linux kernel patch series for upstream submission, including documentation coverage, provenance, recipients, exported patches and dry runs. Also use when asked whether a series is ready to send.
---

# Kernel patch submission

Resolve the kernel repository root with Git. Read the root-relative
.kernel-workflow/upstream.md completely and follow its mandatory-source routing
against the intended target tree, not automatically this fork's revision. Start
a task-specific record from .kernel-workflow/evidence-template.md. Missing source
documents or material evidence remain explicit gaps, not assumed passes.

## Establish the exact series

Record base and tip commit IDs, target tree/branch, version, dependencies and prior
thread. Inspect every commit and its changed paths. Do not infer the series from
the current branch name or include all commits since a convenient upstream tag.
Check for an existing upstream fix and select subsystem subject prefixes from
the relevant history and documented maintainer expectations.

Run the bundled read-only history guard with explicit revisions:

```sh
python .agents/skills/kernel-patch-submit/scripts/check-series.py --repo . --base BASE --tip TIP
```

This checks ancestry, nonempty linear history and agent configuration in every
commit, including files added and later removed. It neither validates the chosen
upstream base nor proves correctness, provenance, or acceptance. Resolve failures
without rewriting user history unless authorized. Inspect exported patch paths
as well; do not treat a clean aggregate diff as proof that every commit is clean.

## Audit, export, and address

Complete applicable documentation coverage and validation in the evidence record.
Review commit explanations, human DCO authorization, licensing, AI disclosure,
and the evidence/permission for every attribution or review trailer. Never invent
a sign-off, reviewer tag, Fixes commit, test result, or Message-ID.

Export only the intended commits using git format-patch and the subsystem's base,
version, cover-letter and threading rules. Run checkpatch on every final patch;
explain justified exceptions. Confirm ordered application to a clean checkout of
the stated base without touching the user's working changes. Review each patch
and cover letter as the recipient will see them.

Run scripts/get_maintainer.pl on the final patches, inspect matching MAINTAINERS
entries and profiles, and validate To/Cc against current subsystem rules and prior
discussion. Generated addresses are candidates, not an instruction to mail all
of them. Follow security, stable and regression procedures only when applicable.

Perform a local dry run with the actual patch files and proposed recipients,
using options supported by the installed tool. Separate formatting success from
delivery success. Sending, even to oneself, requires authorization already given
or obtained for that action; reuse existing authorization rather than asking again.

## Handoff

Provide the exact series/base, artifact paths, recipients, cover letter, checks,
and unresolved gaps. Distinguish source readiness, packaged artifact readiness,
and actual transmission. Do not call the series ready while material requirements
remain unresolved. After an authorized send, record delivery evidence and actual
Message-IDs; use kernel-review-followup for subsequent feedback.
