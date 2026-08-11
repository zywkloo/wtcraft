#!/usr/bin/env python3
"""Bind a Policy Envelope v1 to Git changeset facts and emit evidence.

The caller, not this script, is responsible for fetching a protected policy
ref. This adapter never reads policy from the implementation checkout.
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys

from policy_evaluator import InvalidPolicy, verdict


POLICY_DIRECTORY = ".wtcraft/policies"


class AdapterError(ValueError):
    """The adapter cannot establish an authorization verdict."""


def git(repo, *args, text=True):
    completed = subprocess.run(
        ["git", "-C", repo] + list(args),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=text,
    )
    if completed.returncode != 0:
        detail = completed.stderr.strip() if text else completed.stderr.decode("utf-8", "replace").strip()
        raise AdapterError("git {}: {}".format(" ".join(args), detail or "failed"))
    return completed.stdout


def canonical_digest(policy):
    content = json.dumps(policy, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return "sha256:" + hashlib.sha256(content.encode("utf-8")).hexdigest()


def list_policy_paths(repo, policy_ref):
    raw = git(repo, "ls-tree", "-r", "-z", "--name-only", policy_ref, "--", POLICY_DIRECTORY, text=False)
    paths = []
    for encoded in raw.split(b"\0"):
        if not encoded:
            continue
        path = encoded.decode("utf-8", "surrogateescape")
        if path.endswith(".json"):
            paths.append(path)
    return sorted(paths)


def load_policy_at_ref(repo, policy_ref, path):
    raw = git(repo, "show", "{}:{}".format(policy_ref, path))
    try:
        return json.loads(raw)
    except ValueError as error:
        raise AdapterError("invalid policy JSON at {}: {}".format(path, error))


def policy_candidates(repo, policy_ref, repository, head_ref, merge_base_sha):
    candidates = []
    for path in list_policy_paths(repo, policy_ref):
        policy = load_policy_at_ref(repo, policy_ref, path)
        # Calling verdict with matching no-change facts validates the complete
        # envelope before a malformed authority record can be skipped.
        try:
            verdict(policy, {
                "repository": repository,
                "head_ref": head_ref,
                "merge_base_sha": merge_base_sha,
                "changed_files": [],
            })
        except InvalidPolicy as error:
            raise AdapterError("invalid policy at {}: {}".format(path, error))
        if (
            policy["repository"] == repository
            and policy["head_ref"] == head_ref
            and policy["base_sha"] == merge_base_sha
        ):
            candidates.append(policy)
    return candidates


def emit(value):
    json.dump(value, sys.stdout, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    sys.stdout.write("\n")


def adapter_error(reason, message):
    print(message, file=sys.stderr)
    emit({
        "evidence_version": 1,
        "command": "policy-git-adapter",
        "ok": False,
        "result": "fail",
        "exit_code": 1,
        "error": {"reason": reason, "message": message},
    })
    return 1


def main():
    parser = argparse.ArgumentParser(description="Bind a wtcraft policy envelope to Git facts")
    parser.add_argument("--repo", required=True, help="local checkout with fetched policy and head commits")
    parser.add_argument("--repository", required=True, help="canonical owner/name repository identity")
    parser.add_argument("--head-ref", required=True, help="expected implementation refs/heads/... name")
    parser.add_argument("--head-sha", required=True, help="implementation head commit SHA")
    parser.add_argument("--base-sha", required=True, help="current target-base commit SHA used to compute merge-base")
    parser.add_argument("--policy-ref", default="refs/heads/wtcraft-policy", help="pre-fetched protected policy ref")
    args = parser.parse_args()

    try:
        policy_commit = git(args.repo, "rev-parse", "--verify", args.policy_ref).strip()
    except AdapterError as error:
        return adapter_error("policy_ref_not_found", str(error))

    try:
        merge_base = git(args.repo, "merge-base", args.base_sha, args.head_sha).strip()
        changed_raw = git(args.repo, "diff", "--name-only", "-z", "{}...{}".format(merge_base, args.head_sha), text=False)
        changed_files = [
            path.decode("utf-8", "surrogateescape")
            for path in changed_raw.split(b"\0")
            if path
        ]
        candidates = policy_candidates(
            args.repo, args.policy_ref, args.repository, args.head_ref, merge_base
        )
    except AdapterError as error:
        return adapter_error("invalid_policy", str(error))

    if not candidates:
        return adapter_error("policy_not_found", "no matching policy envelope on {}".format(args.policy_ref))
    if len(candidates) > 1:
        return adapter_error("ambiguous_policy", "multiple matching policy envelopes on {}".format(args.policy_ref))

    policy = candidates[0]
    change = {
        "repository": args.repository,
        "head_ref": args.head_ref,
        "merge_base_sha": merge_base,
        "changed_files": changed_files,
    }
    result = verdict(policy, change)
    exit_code = 0 if result["result"] == "pass" else 2
    evidence = {
        "evidence_version": 1,
        "command": "policy-git-adapter",
        "ok": True,
        "result": result["result"],
        "exit_code": exit_code,
        "policy": {
            "policy_id": policy["policy_id"],
            "source_ref": args.policy_ref,
            "source_commit": policy_commit,
            "digest": canonical_digest(policy),
        },
        "change": {
            "repository": args.repository,
            "head_ref": args.head_ref,
            "base_ref_sha": args.base_sha,
            "merge_base_sha": merge_base,
            "head_sha": args.head_sha,
            "changed_files": changed_files,
        },
        "verdict": result,
    }
    emit(evidence)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
