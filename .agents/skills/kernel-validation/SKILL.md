---
name: kernel-validation
description: Design or execute a focused Linux kernel validation matrix for a patch or series, including configuration coverage, baseline comparison, runtime evidence and explicit testing gaps. Use for test planning or validation beyond a simple build command.
---

# Kernel validation

Resolve the kernel root, follow AGENTS.md, and identify exact base/tip revisions,
changed paths, affected architectures and subsystem ownership. Read the target
tree's Documentation/process/submit-checklist.rst and applicable MAINTAINERS
profiles. Use Documentation/dev-tools/index.rst, Documentation/kbuild/, and the
subsystem's test documentation to select supported commands and configurations.

## Choose evidence that can reveal the risk

Map each material changed behavior to a check and its limits. Consider compile
coverage, linkage, runtime correctness, failure paths and compatibility separately.
A single object build does not prove module or built-in linkage, and checkpatch
does not test behavior. Do not run every tool by default or set arbitrary coverage
percentages unrelated to the change.

Inspect Kconfig dependencies and effective configurations, including built-in and
module cases, CONFIG dependencies, architecture guards and relevant disabled
features. olddefconfig may drop requested options whose dependencies are unmet;
verify resulting values and that affected objects actually build. localmodconfig
may omit the device or path under test. Record random seeds for randconfig.

Use W=1 and sparse, alternate compilers, KUnit/kselftest, fault injection, lockdep,
sanitizers, bindings or documentation builds when they address the identified
risks and are supported. Read each selected tool's target-tree instructions.
Match sanitizer/configuration prerequisites and account for their perturbation
of timing, memory usage and runtime behavior.

## Run reproducibly

Use separate output directories for different revisions/configurations to avoid
stale-object evidence. Record source revision, worktree modifications, config
content or hash, compiler/tool versions, exact commands and output locations.
Choose parallelism from actual memory/disk constraints rather than blindly using
all CPUs; avoid unrelated full builds when a focused check answers the question.

Run comparable base and patched checks when attributing failures or warnings.
Preserve genuine exit status through log pipelines, for example with Bash
pipefail; a successful tee must not turn a failed build into a pass. Distinguish
infrastructure errors, unavailable tools, skipped tests, timeouts and test failures.
Do not silently suppress new warnings or change tests simply to obtain a pass.

For runtime tests, verify device identity, running kernel, module provenance and
the scenario exercised. Compilation, VM boot and actual Yoga Book operation are
separate evidence. Device deployment and reboots require task authorization.
An unavailable device means a documented gap and test procedure, not a pass.

## Deliver an evidence matrix

Use the validation section of .kernel-workflow/evidence-template.md. For each
check record purpose, revision/configuration, command, result/exit status and log.
Explain baseline failures and remaining risk. Retest materially changed code;
old tests remain evidence only for what they actually covered. Include relevant
per-commit buildability checks when delivering a bisectable series.

Report what the results establish and what remains untested. Do not turn tool
success into a claim of upstream acceptance; use kernel-patch-submit when asked
for submission readiness, provenance and recipient checks.
