#!/usr/bin/env python3
"""Run the Policy Envelope v1 contract fixtures against the reference evaluator."""

import json
import os
import subprocess
import sys


REPO_ROOT = os.path.realpath(os.path.join(os.path.dirname(__file__), ".."))
EVALUATOR = os.path.join(REPO_ROOT, "scripts", "policy_evaluator.py")
FIXTURE_ROOT = os.path.join(REPO_ROOT, "tests", "contracts", "policy-envelope")


def load(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def main():
    failures = []
    for name in sorted(os.listdir(FIXTURE_ROOT)):
        case_dir = os.path.join(FIXTURE_ROOT, name)
        case_path = os.path.join(case_dir, "case.json")
        if not os.path.isfile(case_path):
            continue
        case = load(case_path)
        expected = load(os.path.join(case_dir, case["expected"]))
        policy_name = case.get("policy", "policy.json")
        change_name = case["change"]
        command = [
            sys.executable,
            EVALUATOR,
            "--policy",
            os.path.join(case_dir, policy_name),
            "--change",
            os.path.join(case_dir, change_name),
        ]
        completed = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            actual = json.loads(completed.stdout)
        except ValueError as error:
            failures.append("{}: invalid JSON output: {}".format(case["id"], error))
            continue
        if completed.returncode != case["expected_exit_code"]:
            failures.append(
                "{}: expected exit {}, got {}".format(
                    case["id"], case["expected_exit_code"], completed.returncode
                )
            )
        if actual != expected:
            failures.append(
                "{}: expected {}, got {}".format(case["id"], expected, actual)
            )

    if failures:
        for failure in failures:
            print("[FAIL] {}".format(failure), file=sys.stderr)
        return 1
    print("[PASS] contract_policy_envelope")
    return 0


if __name__ == "__main__":
    sys.exit(main())
