---
name: kernel-review-followup
description: Address Linux kernel maintainer review, draft inline replies, prepare revised patch series, or assess submission status using the actual mailing-list thread and current commits.
---

# Kernel review follow-through

Resolve the kernel root and read .kernel-workflow/upstream.md, especially its
follow-through rules. Use the review table in .kernel-workflow/evidence-template.md
to track the actual thread. Read the full relevant discussion and each patch it
reviews; if access is unavailable, identify the missing messages without inventing
their content. Historical submission status is not evidence of current status.

For every reviewer question or request, record its source and one disposition:
implemented with patch/hunk evidence, answered with concrete technical reasoning,
or unresolved. Include small comments as well as major objections. Do not silently
omit a point, assume agreement, or produce a generic acknowledgment in place of
an answer. Respect the requested scope: drafting a reply does not authorize code
changes or sending mail.

When revising, inspect the implementation and dependencies before changing code.
Map edits to review points and avoid unrelated cleanup. Reassess previously granted
review/test tags when code changes materially. Follow the subsystem's revision and
threading rules; read direct maintainer instructions rather than hard-coding one
threading strategy for all subsystems.

Prepare a concise version changelog, link the previous version, and provide a
range-diff when useful or required. Revalidate affected behavior and the final
series through kernel-patch-submit. Increment the version for changed patches;
RESEND means unchanged patches. Never reuse old test evidence for materially
different code without stating its limits.

Draft plain-text inline replies with relevant trimmed quotations and direct
answers. Keep permanent rationale in commit messages and transient revision notes
below the patch separator or in the cover letter. Follow AGENTS.md for the user's
mail signature. Show the exact draft when asked, not merely advice about replying.

Sending replies or revisions requires authorization for that action. Do not ping
or resend just because the thread is silent; follow documented intervals and
maintainer availability. If asked to wait or monitor, use the available monitoring
mechanism and report observed changes without manufacturing a reason to repost.

For status reports, distinguish posted, reviewed, queued in a maintainer tree,
and merged upstream. Verify actual commit IDs and patch equivalence when rebases
change hashes. State which review points or acceptance checks remain open.
