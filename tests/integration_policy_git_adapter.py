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


def create_repo(changed_path=None, rename_from=None, rename_to=None):
    repo = tempfile.mkdtemp(prefix="wtcraft-policy-adapter-")
    run(repo, "init", "-q")
    run(repo, "config", "user.name", "wtcraft-tests")
    run(repo, "config", "user.email", "wtcraft-tests@example.com")
    write(os.path.join(repo, "README.md"), "seed\n")
    write(os.path.join(repo, "src", "seed.txt"), "seed\n")
    write(os.path.join(repo, ".github", "workflows", "ci.yml"), "protected\n")
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
    if rename_from:
        run(repo, "mv", rename_from, rename_to)
    if changed_path:
        write(os.path.join(repo, changed_path), "change\n")
        run(repo, "add", changed_path)
    run(repo, "commit", "-q", "-m", "implementation")
    return repo, base_sha, run(repo, "rev-parse", "HEAD"), policy_commit


def create_shallow_consumer():
    """Reproduce the CI shape: depth-1 base checkout, base branch moved on.

    Returns the shallow working clone plus the base tip and head SHA a
    pull_request_target job would pass in.
    """

    origin, base_sha, head_sha, _ = create_repo("src/implementation.txt")
    default_branch = "wtcraft-base"
    run(origin, "checkout", "-q", "-b", default_branch, base_sha)
    write(os.path.join(origin, "README.md"), "base moved on\n")
    run(origin, "commit", "-q", "-am", "advance base past the fork point")
    base_tip = run(origin, "rev-parse", "HEAD")

    workdir = tempfile.mkdtemp(prefix="wtcraft-policy-shallow-")
    clone = os.path.join(workdir, "work")
    subprocess.run(
        ["git", "clone", "-q", "--depth", "1", "--branch", default_branch,
         "file://" + origin, clone],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True,
    )
    run(clone, "fetch", "-q", "--no-tags", "--depth", "1", "origin",
        "+refs/heads/wtcraft-policy:refs/heads/wtcraft-policy",
        "+refs/heads/feat/trusted-change:refs/heads/wtcraft-pr-head")
    shutil.rmtree(origin, ignore_errors=True)
    return clone, base_tip, head_sha


def evaluate(repo, base_sha, head_sha, head_ref="refs/heads/feat/trusted-change",
             repository="acme/widget"):
    completed = subprocess.run(
        [
            sys.executable,
            ADAPTER,
            "--repo", repo,
            "--repository", repository,
            "--head-ref", head_ref,
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
        # Evidence must name the reviewed plan and admit it did not run it.
        assert evidence["verification"]["status"] == "not_executed"
        assert evidence["verification"]["plan"] == [
            {"name": "unit", "command": "bash tests/run_all.sh"}
        ]

        repo, base_sha, head_sha, policy_commit = create_repo("docs/not-authorized.md")
        repos.append(repo)
        code, evidence, stderr = evaluate(repo, base_sha, head_sha)
        assert code == 2, stderr
        assert evidence["ok"] is True
        assert evidence["result"] == "fail"
        assert evidence["verdict"]["reason"] == "scope_violation"
        assert evidence["verdict"]["violations"] == ["docs/not-authorized.md"]
        assert evidence["policy"]["source_commit"] == policy_commit

        # Moving a file out of an off_limits directory must not launder it into
        # allowed_paths. Git's default rename detection reports only the
        # destination, which would authorize the change.
        repo, base_sha, head_sha, _ = create_repo(
            rename_from=".github/workflows/ci.yml", rename_to="src/ci.yml"
        )
        repos.append(repo)
        code, evidence, stderr = evaluate(repo, base_sha, head_sha)
        assert code == 2, "rename out of off_limits was authorized: {}".format(evidence)
        assert evidence["verdict"]["reason"] == "scope_violation"
        assert evidence["verdict"]["violations"] == [".github/workflows/ci.yml"]
        assert ".github/workflows/ci.yml" in evidence["change"]["changed_files"]
        assert "src/ci.yml" in evidence["change"]["changed_files"]

        # Change facts the caller got wrong must still produce parseable
        # evidence rather than an uncaught traceback.
        repo, base_sha, head_sha, _ = create_repo("src/implementation.txt")
        repos.append(repo)
        code, evidence, stderr = evaluate(repo, base_sha, head_sha, head_ref="feat/trusted-change")
        assert code == 1, stderr
        assert evidence["ok"] is False
        assert evidence["error"]["reason"] == "invalid_change"
        assert "Traceback" not in stderr

        # A depth-1 clone cannot answer merge-base once the base branch has
        # advanced past the fork point, which is the ordinary case. That is a
        # transport defect, not a malformed policy, and must say so.
        clone, base_tip, head_sha = create_shallow_consumer()
        repos.append(os.path.dirname(clone))
        code, evidence, stderr = evaluate(clone, base_tip, head_sha)
        assert code == 1, "expected shallow merge-base failure, got {}".format(evidence)
        assert evidence["ok"] is False
        assert evidence["error"]["reason"] == "merge_base_unavailable", evidence
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
