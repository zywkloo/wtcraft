#!/usr/bin/env python3
"""Exercise the Git-backed policy adapter in isolated repositories."""

import json
import os
import shutil
import subprocess
import sys
import tempfile


REPO_ROOT = os.path.realpath(os.path.join(os.path.dirname(__file__), ".."))
ADAPTER = os.path.join(REPO_ROOT, "scripts", "policy_git_adapter.py")
BASE_SHA = "placeholder"


def run(repo, *args):
    completed = subprocess.run(
        ["git", "-C", repo] + list(args),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError("git {}: {}".format(" ".join(args), completed.stderr))
    return completed.stdout.strip()


def write(path, content):
    parent = os.path.dirname(path)
    if not os.path.isdir(parent):
        os.makedirs(parent)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(content)


def make_policy(base_sha):
    return {
        "schema_version": 1,
        "policy_id": "adapter-policy-001",
        "task_id": "adapter integration",
        "repository": "acme/widget",
        "head_ref": "refs/heads/feat/trusted-change",
        "base_sha": base_sha,
        "allowed_paths": ["src/**"],
        "off_limits": [".github/**"],
        "verification": [{"name": "unit", "command": "bash tests/run_all.sh"}],
    }


def create_repo(changed_path):
    repo = tempfile.mkdtemp(prefix="wtcraft-policy-adapter-")
    run(repo, "init", "-q")
    run(repo, "config", "user.name", "wtcraft-tests")
    run(repo, "config", "user.email", "wtcraft-tests@example.com")
    write(os.path.join(repo, "README.md"), "seed\n")
    write(os.path.join(repo, "src", "seed.txt"), "seed\n")
    run(repo, "add", ".")
    run(repo, "commit", "-q", "-m", "seed")
    base_sha = run(repo, "rev-parse", "HEAD")

    run(repo, "checkout", "-q", "-b", "wtcraft-policy")
    policy_path = os.path.join(repo, ".wtcraft", "policies", "adapter-policy-001.json")
    write(policy_path, json.dumps(make_policy(base_sha), sort_keys=True) + "\n")
    run(repo, "add", ".wtcraft/policies/adapter-policy-001.json")
    run(repo, "commit", "-q", "-m", "authorize task")
    policy_commit = run(repo, "rev-parse", "HEAD")

    run(repo, "checkout", "-q", "-b", "feat/trusted-change", base_sha)
    write(os.path.join(repo, changed_path), "change\n")
    run(repo, "add", changed_path)
    run(repo, "commit", "-q", "-m", "implementation")
    return repo, base_sha, run(repo, "rev-parse", "HEAD"), policy_commit


def evaluate(repo, base_sha, head_sha):
    completed = subprocess.run(
        [
            sys.executable,
            ADAPTER,
            "--repo", repo,
            "--repository", "acme/widget",
            "--head-ref", "refs/heads/feat/trusted-change",
            "--head-sha", head_sha,
            "--base-sha", base_sha,
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    return completed.returncode, json.loads(completed.stdout), completed.stderr


def main():
    repos = []
    try:
        repo, base_sha, head_sha, policy_commit = create_repo("src/implementation.txt")
        repos.append(repo)
        code, evidence, stderr = evaluate(repo, base_sha, head_sha)
        assert code == 0, stderr
        assert evidence["ok"] is True
        assert evidence["result"] == "pass"
        assert evidence["policy"]["source_ref"] == "refs/heads/wtcraft-policy"
        assert evidence["policy"]["source_commit"] == policy_commit
        assert evidence["policy"]["digest"].startswith("sha256:")
        assert evidence["change"]["changed_files"] == ["src/implementation.txt"]

        repo, base_sha, head_sha, policy_commit = create_repo("docs/not-authorized.md")
        repos.append(repo)
        code, evidence, stderr = evaluate(repo, base_sha, head_sha)
        assert code == 2, stderr
        assert evidence["ok"] is True
        assert evidence["result"] == "fail"
        assert evidence["verdict"]["reason"] == "scope_violation"
        assert evidence["verdict"]["violations"] == ["docs/not-authorized.md"]
        assert evidence["policy"]["source_commit"] == policy_commit
    except (AssertionError, RuntimeError, ValueError) as error:
        print("[FAIL] integration_policy_git_adapter: {}".format(error), file=sys.stderr)
        return 1
    finally:
        for repo in repos:
            shutil.rmtree(repo, ignore_errors=True)

    print("[PASS] integration_policy_git_adapter")
    return 0


if __name__ == "__main__":
    sys.exit(main())
