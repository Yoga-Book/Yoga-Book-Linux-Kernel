---
name: kernel-regression-debug
description: Isolate a Linux kernel regression using a reproducible failure, controlled good/bad comparisons, bisection and causal verification. Use when behavior worked previously or an introducing commit needs verification.
---

# Kernel regression debugging

Resolve the kernel root and follow applicable AGENTS.md instructions. A diagnosis
request authorizes investigation, not implementing or publishing a fix. Read the
target tree's Documentation/admin-guide/verify-bugs-and-bisect-regressions.rst,
bug-bisect.rst, and Documentation/process/handling-regressions.rst. Locate renamed
documents through the target tree's indexes if necessary.

## Establish a reliable comparison

Begin with the exact reported failure. Record the reproducer, expected outcome,
failure signature and frequency, last known good and first known bad revisions,
hardware identity, firmware, userspace, kernel configuration, command line,
toolchain and relevant modules. Verify the running kernel actually matches the
tested artifact; a successful installation command is insufficient evidence.

Recheck good and bad endpoints with comparable conditions. Account for changes
outside the kernel and for configuration differences. A dependency or missing
module can mimic a source regression. For intermittent failures, establish a
repeatable trial protocol and retain counts; one passing attempt is not proof
that a candidate is good. Do not impose a universal number of trials.

Use current source, callers and history to form falsifiable hypotheses. Use
CodeGraph first when indexed. A blame result, temporal correlation or first
failing commit is a lead until the failure mechanism is understood.

## Bisect without contaminating the experiment

Use a separate worktree or checkout, preserving the user's branch and edits.
Record configuration generation and artifact identity at each step. Keep the
reproducer and test conditions stable; document necessary compatibility changes.
Retain git bisect log and each revision's result so work can be replayed.

For automated git bisect run, inspect the runner: 0 means good, 1-127 except
125 means bad, and 125 means skip. Harness errors such as missing commands must
not accidentally become bad-kernel evidence; abort on infrastructure failure.
Skip unrelated unbuildable or genuinely untestable revisions with a reason.
Report an ambiguous set of candidates when skips prevent a unique result.

Deployment, rebooting, firmware and disk actions still require authorization for
that scope. When device access is unavailable, prepare a concrete human test
procedure instead of labeling unbooted candidates good or bad. Keep a known-good
recovery path for an authorized device test.

## Verify causality and hand off

Retest the suspected commit and its parent where possible, and use a controlled
revert or forward fix when appropriate in the isolated checkout. Explain the
mechanism and confounders; a revert that removes several behaviors is not alone
proof of which behavior caused the failure. Distinguish a commit exposing an
older bug from the commit introducing that bug before proposing a Fixes tag.

Report the verified range or culprit, reproducer, conditions, bisect log, source
evidence and remaining uncertainty. Recheck the fix against the original failure
and relevant neighboring behavior. Route implementation to kernel-development
and an actual submission to kernel-patch-submit; do not send regression reports
or tracking commands without authorization for the external message.
