# Kernel patch evidence record

Copy this template to a task-specific local location. Do not include it in the
upstream patch unless requested by the subsystem. No checkbox is proof by itself.

## Scope and source identity

- Request / failure / reproducer:
- Target repository, branch, base commit and documentation revision:
- Working branch, HEAD, exact series range, version and dependencies:
- Changed subsystem(s) and matched MAINTAINERS entries/profiles:
- Prior discussion URLs and verified Message-IDs:
- Current upstream/history check:

## Documentation coverage

Use one row per applicable requirement, not merely one row per document.
Allowed dispositions: satisfied, not applicable (explain), unresolved.

| Document and section at target revision | Requirement | Evidence / artifact | Disposition and reason |
| --- | --- | --- | --- |
| | | | |

List unavailable/unread references explicitly:

## Technical review

| Concern | Findings and source locations | Resolution or justified non-applicability |
| --- | --- | --- |
| Root cause, reproducer, regression and introducing commit | | |
| Locking, atomic context, races and memory ordering | | |
| Ownership, lifetime, error unwind and teardown | | |
| Bounds, security, ABI and configuration compatibility | | |
| PM, device behavior and performance | | |
| Logical split, dependencies and per-commit buildability | | |

## Validation

| Exact command | Commit / config / tool version / hardware | Result and exit status | Log or artifact |
| --- | --- | --- | --- |
| | | | |

- Baseline comparison and new warnings:
- Reproducer before/after:
- Checkpatch findings and justified exceptions:
- Series application to clean stated base:
- Real-device evidence versus VM/build evidence:
- Checks not run, reasons, and proposed human test procedure:

## Provenance and final mail

- Author identity and human authorization for DCO sign-off:
- AI disclosure and target subsystem policy:
- Evidence/permission for each attribution and review/test trailer:
- Exact exported patch files and confirmation of no local agent files/artifacts:
- Proposed To/Cc and justification from current maintainer rules:
- Exact subject, cover letter, version, base, dependencies and threading:
- Dry-run command and inspected result:
- Remaining issues and their effect on readiness:
- Authorization for actual sending (if given):
- Sent Message-IDs / delivery evidence (only after sending):

## Review and acceptance

| Review comment / URL | Required action | Resolution and patch/hunk or reply | State |
| --- | --- | --- | --- |
| | | | |

- Previous version, changelog and range-diff:
- Revalidation after revisions:
- Observed maintainer-tree/upstream commit and verification date:
