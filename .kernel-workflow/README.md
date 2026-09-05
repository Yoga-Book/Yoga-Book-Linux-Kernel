# Local LLM configuration

`LLM-Config` is an independent configuration-only branch. It has no kernel
ancestry and must never be merged or cherry-picked into kernel patch branches.
It can be published separately to the Yoga-Book GitHub fork when authorized.

The active kernel checkout uses local, untracked copies of `AGENTS.md` and
`.kernel-workflow/`. Root-anchored entries in `.git/info/exclude` prevent normal
staging of these paths without changing the kernel's tracked `.gitignore`.
Exclusion does not prevent `git add -f` or override already tracked files.

To recover the saved configuration without switching the kernel checkout, run
from the kernel repository root:

```sh
config_copy=$(mktemp -d /tmp/yogabook-llm-restore.XXXXXX)
git archive LLM-Config -- AGENTS.md .kernel-workflow | tar -x -C "$config_copy"
diff -u AGENTS.md "$config_copy/AGENTS.md"
diff -ru .kernel-workflow "$config_copy/.kernel-workflow"
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
