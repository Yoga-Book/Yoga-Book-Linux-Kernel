#!/usr/bin/env python3
"""Read-only history guard; does not certify upstream submission readiness."""

import argparse
import subprocess
import sys
from pathlib import PurePosixPath


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".")
    parser.add_argument("--base", required=True)
    parser.add_argument("--tip", default="HEAD")
    args = parser.parse_args()

    def git(*arguments):
        return subprocess.check_output(
            ["git", "-C", args.repo, *arguments], stderr=subprocess.PIPE
        )

    try:
        base = git("rev-parse", "--verify", "--end-of-options", args.base + "^{commit}").decode().strip()
        tip = git("rev-parse", "--verify", "--end-of-options", args.tip + "^{commit}").decode().strip()
        git("merge-base", "--is-ancestor", base, tip)
        commits = git("rev-list", "--reverse", "--topo-order", base + ".." + tip).decode().splitlines()
        if not commits:
            print("FAIL: empty series", file=sys.stderr)
            return 1
        failures = []
        for commit in commits:
            parents = git("rev-list", "--parents", "-n", "1", commit).decode().split()[1:]
            if len(parents) != 1:
                failures.append(f"{commit[:12]}: expected a linear patch commit")
                continue
            paths = git("diff-tree", "--no-commit-id", "--name-only", "--no-renames",
                        "-r", "-z", parents[0], commit).split(b"\0")
            for raw_path in filter(None, paths):
                path = raw_path.decode("utf-8", errors="surrogateescape")
                parts = PurePosixPath(path).parts
                if (set(parts) & {".agent", ".agents", ".codex", ".kernel-workflow"}
                        or parts[-1] in {"AGENTS.md", "AGENTS.override.md"}):
                    failures.append(f"{commit[:12]}: local agent configuration {path!r}")
        if failures:
            print("FAIL:\n" + "\n".join(failures), file=sys.stderr)
            return 1
        print(f"PASS: {len(commits)} linear commits; no agent configuration changes")
        print("Base suitability, exported patches, documentation and tests still require review.")
        return 0
    except subprocess.CalledProcessError as error:
        detail = error.stderr.decode(errors="replace").strip()
        print("FAIL: Git validation failed; check revisions and base ancestry. " + detail,
              file=sys.stderr)
        return 2
    except OSError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
