# Upstream kernel workflow

This is a routing guide, not a replacement for kernel documentation. Read sources
from the intended target tree at the revision used for the series. Use official
kernel.org documentation and the actual subsystem tree when local sources are
missing or stale; report unavailable sources instead of asserting compliance.

## 1. Establish the contract and read the sources

Before preparing a submission, read these files completely:

- `Documentation/process/submitting-patches.rst`
- `Documentation/process/submit-checklist.rst`
- `Documentation/process/coding-style.rst`
- `Documentation/process/generated-content.rst`
- `Documentation/process/email-clients.rst`
- `Documentation/process/handling-regressions.rst`
- `Documentation/process/maintainer-handbooks.rst`
- `Documentation/maintainer/maintainer-entry-profile.rst`

Inspect `Documentation/process/index.rst`, `Documentation/maintainer/index.rst`,
and every `MAINTAINERS` entry matching changed paths. Follow applicable `P:`
profiles, `F:`/`N:` patterns and exclusions, subsystem rules, and documentation
links. Record the precise target tree/branch and its submission preferences.
Read applicable linked instructions completely; if output is truncated, continue
through the remaining sections. Track coverage in the evidence record.

Additional routing (not an exhaustive list):

| Change or activity | Sources to read when applicable |
| --- | --- |
| First contribution / process uncertainty | `Documentation/process/howto.rst`, `development-process.rst`, `5.Posting.rst`, `6.Followthrough.rst`, `7.AdvancedTopics.rst` |
| Stable fix / backport | `Documentation/process/stable-kernel-rules.rst`, `backporting.rst` |
| Security vulnerability | `Documentation/process/security-bugs.rst`; follow private reporting rules before publishing exploit details |
| Regressions | `Documentation/admin-guide/reporting-regressions.rst`; existing regression thread and tracking conventions |
| Tests / analysis | `Documentation/dev-tools/`, relevant kselftest/KUnit and subsystem test documentation |
| Driver changes | Applicable `Documentation/driver-api/`, bus, locking, power-management, and subsystem documentation |
| Device tree | `Documentation/devicetree/bindings/`, binding submission rules, schema and DT validation instructions |
| Userspace interfaces | `Documentation/ABI/`, `Documentation/userspace-api/`, `Documentation/process/adding-syscalls.rst` when applicable |
| Networking / DRM / other subsystems | Subsystem maintainer handbook and patch acceptance rules, including tree and versioning conventions |
| Documentation | `Documentation/doc-guide/` and affected documentation build targets |

If a path does not exist at the target revision, locate its replacement through
that tree's indexes. Record the replacement or the unresolved gap.

## 2. Establish the problem and base

Record the actual failure, reproducer, affected versions/configuration/hardware,
expected behavior, and diagnostic evidence. Check history and current upstream to
avoid resubmitting an existing fix. Distinguish fixes from features and cleanup.
Resolve the introducing commit before adding `Fixes:`; do not guess from blame.
Choose the maintainer's fixes or development tree as appropriate, with explicit
cross-tree dependencies. Fetch/rebase only within authorized scope and preserve
unrelated work. A local fork's merge base alone is not proof of upstream fit.

For Yoga Book work, distinguish compilation, VM tests, and tests on the actual
tablet. Verify the running kernel/image and device identity before attributing
device results to a patch. Do not reuse an older submission's state as current.

## 3. Implement and verify

Review the changed logic and callers, lock ordering and atomic context, lifetime
and reference counts, error/partial initialization cleanup, remove/unload paths,
PM suspend/resume, concurrency, memory ordering, bounds, ABI and performance as
applicable. Prefer established APIs and the smallest complete fix.

Use the target documentation to select an appropriate validation matrix:

- Inspect every commit and the aggregate diff with `git diff --check`.
- Run `scripts/checkpatch.pl --strict` on every exported patch. Resolve warnings
  or document a justified exception; never make mechanical changes solely to
  silence the tool when they conflict with subsystem style.
- Build affected configurations, normally including `W=1`, relevant built-in
  and module settings, and affected architectures. Compare new warnings against
  the baseline. Use an output directory outside source when practical.
- Use sparse (`C=1`/`C=2`), Smatch, Clang, sanitizers, lockdep, fault injection,
  KUnit/kselftest, and subsystem tooling where supported and relevant. Do not
  claim unavailable tools ran. Avoid exhaustive unrelated builds by default.
- Run the reproducer and regression tests; test failure and teardown paths.
  Record hardware gaps and provide a concrete human test procedure if needed.
- Run `dt_binding_check`/`dtbs_check`, documentation builds, or ABI checks when
  applicable. Consult the target tree for exact supported command options.
- Verify each commit is independently sensible and buildable. Check the final
  exported series applies in order to a clean isolated checkout of its stated
  base. Never apply trial patches on top of the user's working changes.

Keep commands, configuration/toolchain identity, logs, and outcomes. Distinguish
not run, failed, passed, and not applicable with a reason. Do not label a patch
ready when a material issue remains unexplained.

## 4. Prepare a reviewable patch series

For each commit: use the subsystem's subject prefix and a concise imperative
summary; explain the problem, user-visible impact, root cause, solution, and
relevant tradeoffs. Include enough context to stand alone, without making the
commit message a chronological transcript. Wrap prose as submitting-patches
specifies. Keep revision notes and transient test details below `---` or in the
cover letter as appropriate.

Audit author identity, DCO authorization, licensing, and every trailer. Apply
`Fixes:`, `Closes:`, `Link:`, `Reported-by:`, `Tested-by:`, `Reviewed-by:`,
`Acked-by:`, `Co-developed-by:`, and stable Cc only according to documented
semantics and real evidence/permission. Never create reviewer approval. Reassess
whether existing tags still apply after changes. Follow the generated-content
policy: use `Assisted-by: LLM` for substantive assistance; only the authorized
human certifies `Signed-off-by:`. Respect reporter privacy and consent.

Export the exact intended commits with `git format-patch`, a documented base
(`--base` when applicable), version, and cover letter when useful or required.
Inspect subjects, message bodies, trailers, diffstats, dependencies, and all
exported file paths. Exclude AGENTS.md, `.kernel-workflow/`, build artifacts,
device evidence bundles, and other unrelated local files from upstream patches.

## 5. Resolve recipients and the transport

Run `scripts/get_maintainer.pl` on the final patches and inspect the matching
`MAINTAINERS` entries manually. Treat generated addresses as candidates. Check
active maintainer profiles, list rules, current history, and the prior thread;
choose appropriate To/Cc without blanket mailing everyone or defaulting to Linus.
Respect stable and regression Cc rules only when they apply. Use lore/kernel.org
thread URLs and actual Message-IDs, never invented or remembered IDs.

Use the subsystem's documented transport, typically plain-text `git send-email`
or b4. Verify the installed tool's help before choosing options. Check whitespace,
encoding, threading, subject version, recipients, base information, and cover
letter. Perform a local dry run using the exact intended patch files and
recipients; do not expose SMTP credentials in logs. Distinguish local formatting
checks from successful delivery. Any self-test email is still sending mail and
requires authorization. Do not substitute a GitHub PR unless that subsystem
explicitly accepts it.

Before an authorized send, present the exact series, recipient list, cover letter,
validation summary and remaining limitations. Resolve material compliance or
provenance gaps first. Request permission only if the actual send is not already
authorized. Record the resulting message identifiers and delivery evidence.

## 6. Follow through

Read the entire relevant review thread. Track each comment and its disposition:
fixed in a named patch/hunk, answered with evidence, or still open. Reply inline
with trimmed quotes; address technical questions directly. Do not treat silence
as approval or automated success as proof of acceptance.

For v2 and later, account for every review comment, link the prior version,
include a concise version changelog and appropriate range-diff, revalidate the
changed series, and follow subsystem threading rules. Increment the version for
modified patches; use RESEND only for unchanged patches. Follow the documented
reminder interval (submitting-patches currently says at least one week, often
longer) and maintainer availability instead of repeated pings.

Verify acceptance in the maintainer tree and eventual upstream inclusion using
actual commits, accounting for rebases. Report the observed state precisely;
posting, receiving a review tag, and merging are different outcomes.
