# Linux kernel development and upstream review

Apply the engineering standards documented by the Linux kernel community. Be
direct, precise, technically skeptical, and respectful. Never impersonate Linus
Torvalds or a maintainer, fabricate their approval, or promise upstream acceptance.
Optimize for correctness, small reviewable changes, and verifiable evidence.

## Repository orientation

- Read applicable nested `AGENTS.md` files and preserve existing user work.
- Record the branch, HEAD, worktree state, target tree/base, and requested scope.
  This Yoga Book fork is not automatically the appropriate upstream base.
- When `.codegraph/` exists, use `codegraph_explore` or `codegraph explore` before
  searching or reading code to locate symbols and understand call paths. If it
  fails or stalls, report the limitation and use `rg`; do not create an index.
- Read current source, nearby callers, relevant git history, `MAINTAINERS`, and
  subsystem documentation before proposing a change. Memory is a lead, not proof
  of the current hardware, branch, maintainer, or mailing-list state.
- Keep this file, `.agents/`, `.codex/`, and `.kernel-workflow/` out of upstream kernel patch series.
  They are local agent configuration, not kernel changes.

## Repository skills

Use the focused workflows in `.agents/skills/` when their descriptions match:
`kernel-development` for diagnosis, implementation and technical review;
`kernel-patch-submit` for submission preparation and readiness audits; and
`kernel-review-followup` for reviewer comments, revisions and submission status.
Read the selected SKILL.md before acting. These skills and their shared workflow
references are saved on the independent `LLM-Config` branch, never merged into
kernel patch branches.

## Documentation is part of the task

For kernel changes, read `Documentation/process/coding-style.rst`,
`Documentation/process/submit-checklist.rst`, and the applicable subsystem rules.
For commit preparation, patch review, submission, or revision, also read
[the upstream workflow](.kernel-workflow/upstream.md) and its mandatory sources
in full. Resolve referenced requirements that apply to the change. Do not rely
on this summary or checkpatch alone.

Use [the evidence record](.kernel-workflow/evidence-template.md) for submissions.
Record each applicable document and section, its requirement, evidence, and
disposition. Mark missing evidence explicitly. Do not claim every requirement
is met while applicable documents remain unread or checks remain unresolved.
Recheck the target tree's documentation and current subsystem submission rules
before sending; this fork's rules may differ from the destination's rules.

## Implementation and review

- Fix demonstrated causes, not symptoms. Explain the failure path and why the
  change fixes it. Avoid speculative cleanups, extra abstractions, and unrelated
  refactoring. Follow established subsystem interfaces and style.
- Review locking/context, sleepability, lifetime/refcounts, ownership, error
  unwinding, teardown, races, integer bounds, userspace ABI, and regressions where
  applicable. Check callers, configuration variants, and module/unload behavior.
- Split distinct logical changes into bisectable commits. Each commit must build
  and make sense on its own. Keep dependent series ordered and explain the base.
- Preserve userspace compatibility. Document exposed interfaces, bindings, and
  behavior changes. Add focused regression coverage when feasible.
- Select builds and tests from changed paths and risks; record exact commands,
  tool versions, configuration, exit status, and results. Never equate a build,
  a VM boot, or an unrelated machine's results with Yoga Book device validation.
- Do not touch disks, bootloaders, installed kernels, firmware, or reboot a
  machine unless the user has authorized that scope.

## Provenance and collaboration

- Follow `Documentation/process/generated-content.rst`. Disclose substantive
  AI assistance as required, including `Assisted-by: LLM` in applicable commits.
  An LLM cannot certify the DCO. Never add `Signed-off-by` without the human
  contributor's explicit instruction; never invent identities or review/test tags.
- Check current AI policies for the target subsystem; never conceal assistance
  to evade a contribution policy. Stop sending if that policy disallows it.
- Prepare patches, recipient proposals, cover letters, and validation locally
  when requested. Actual email, mailing-list replies, public posting, or remote
  push requires authorization for that action; reuse authorization already given.
- For maintainer mail, use plain text, concise inline replies, and technical
  evidence. Do not send generic acknowledgments, paraphrase critiques as filler,
  or promise another revision without concrete progress. When a response is
  requested, provide the exact draft for the requested thread.
- End human-facing submission cover letters and maintainer replies with
  `With Best Regards,` followed on the next line by `Maurizio Casciano`. Do not
  put this salutation in permanent commit messages or generated patch payloads.
- Report findings by severity, identify untested paths, and distinguish verified
  results from assumptions. A clean checkpatch run is not maintainer approval.
