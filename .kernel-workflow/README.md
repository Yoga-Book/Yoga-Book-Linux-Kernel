# Local LLM configuration

`LLM-Config` is an independent configuration-only branch. It has no kernel
ancestry and must never be merged or cherry-picked into kernel patch branches.
It can be published separately to the Yoga-Book GitHub fork when authorized.

The active kernel checkout uses local, untracked copies of `AGENTS.md`,
`.kernel-workflow/`, `.agents/skills/`, and `.codex/config.toml`. Root-anchored entries in
`.git/info/exclude` exclude the first two paths; the kernel's existing `.*`
ignore rule also excludes `.codex/` and `.agents/` without changing tracked `.gitignore` files.
Exclusion does not prevent `git add -f` or override already tracked files.

Only `.codex/config.toml` is versioned from `.codex/`; do not add credentials,
session state, or caches. The configuration expects `codegraph`, `engram`,
`npx`, and `uvx` on PATH and a local Firecrawl service on port 3002. Its existing
MCP settings are preserved; installing this file does not install those services.

Repository skills live in `.agents/skills/` (plural), the Codex discovery path.
Use `$kernel-development`, `$kernel-patch-submit`, or `$kernel-review-followup`
explicitly, or allow Codex to select a matching skill automatically. If newly
installed skills do not appear, restart Codex. The submission skill includes a
read-only history guard that rejects local agent files even when a later commit
removes them again; it is not a substitute for patch review or kernel validation.

Specialized skills deepen selected parts of that workflow:

- `$kernel-regression-debug`: controlled good/bad comparisons and bisection.
- `$kernel-validation`: configuration coverage and reproducible test evidence.
- `$kernel-driver-lifecycle-review`: ownership, teardown races and power management.
- `$kernel-stable-backport`: stable eligibility, dependencies and older-tree semantics.

Use these when the task calls for that depth; they are not mandatory steps for
every patch and do not grant permission to deploy, reboot or send mail.

To recover the saved configuration without switching the kernel checkout, run
from the kernel repository root:

```sh
config_copy=$(mktemp -d /tmp/yogabook-llm-restore.XXXXXX)
git archive LLM-Config -- AGENTS.md .kernel-workflow .codex/config.toml .agents/skills | tar -x -C "$config_copy"
diff -u AGENTS.md "$config_copy/AGENTS.md"
diff -ru .kernel-workflow "$config_copy/.kernel-workflow"
diff -u .codex/config.toml "$config_copy/.codex/config.toml"
diff -ru .agents/skills "$config_copy/.agents/skills"
```

The temporary copy is available for inspection even if the local files are
missing. After reviewing differences and preserving any local edits, copy the
desired files back. Do not blindly overwrite newer configuration. Each new
clone needs its own local exclusions. Check these in linked worktrees too;
configuration file contents are not automatically copied between worktrees.

For updates, use a separate checkout of `LLM-Config` (or a temporary Git index),
copy only reviewed configuration changes, and commit them on that branch. Do
not switch the active kernel checkout to this configuration-only branch.
Changes to local copies are not saved to the branch automatically.

Before exporting upstream patches, verify that their commits and exported paths
contain no agent configuration. No push, hook, or automatic synchronization is
installed by this setup.
