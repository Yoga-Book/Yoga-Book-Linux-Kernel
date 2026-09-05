---
name: kernel-development
description: Diagnose, implement, or review Linux kernel changes with subsystem-specific reasoning and a risk-based validation plan. Use for kernel code work, not merely packaging an existing patch series.
---

# Kernel development

Resolve the kernel repository root with Git; documentation paths below are
relative to that root. Honor the requested mode: a diagnosis or review does not
authorize implementation. Follow the root AGENTS.md and any nested instructions.

## Establish evidence before editing

Start with the supplied failure, stack trace, reproducer, or changed symbol.
Record the target revision, architecture, configuration and actual running
kernel when runtime evidence matters. Use CodeGraph first when indexed, then
inspect current source, callers, and history. Identify the owning MAINTAINERS
entries and read their profiles and applicable subsystem documentation.

Read Documentation/process/coding-style.rst and submit-checklist.rst completely.
For AI-assisted changes, read generated-content.rst and the target subsystem's
current contribution policy. Check whether the problem is already fixed upstream
and whether the intended target is a fixes or development tree.

Explain the causal failure path before choosing a fix. Separate observed facts
from hypotheses; a suspicious pattern or static analyzer finding is not itself
a demonstrated bug. Prefer a minimal complete change using subsystem APIs.

## Review by applicable risk

Follow object ownership through allocation, publication, use, failure and removal.
Check lock ordering, sleeping in atomic context, refcounts, work/timer cancellation,
interrupt and DMA lifetime, partial probe failure, module unload, and suspend/resume
when those paths are touched. Check integer bounds, userspace compatibility,
configuration guards and callers outside the immediate file.

Separate logical changes into independently understandable, buildable commits.
Avoid unrelated cleanup, broad mechanical style edits and speculative abstractions.
Explain unavoidable changes in behavior and update relevant ABI/binding/docs.

## Select and record validation

Choose configurations and tools that can falsify the specific failure hypothesis:
affected architecture and built-in/module builds, W=1, sparse, KUnit/kselftest,
lockdep, sanitizers, fault injection, bindings or documentation builds as relevant.
Use documented targets and compare new warnings with the unchanged baseline.
Record exact revision, commands, config, tool versions, exit status and evidence.
Do not make unrelated exhaustive builds a prerequisite for a narrow diagnosis.

For Yoga Book runtime claims, verify the device and installed/running image.
Distinguish compilation, VM results, and actual tablet results. Deployment,
reboots, firmware and disk changes need task authorization. If hardware is
unavailable, provide a concrete test procedure and mark the result untested.

Finish with the cause or change, evidence, relevant source locations, tests and
remaining gaps. When preparing a submission, use kernel-patch-submit and the
repository's .kernel-workflow/upstream.md; development evidence alone is not a
completed submission audit.
