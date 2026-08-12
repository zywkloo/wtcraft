#!/usr/bin/env python3
"""Run the Policy Envelope v1 contract fixtures against the reference evaluator."""

import json
import os
import subprocess
import sys


REPO_ROOT = os.path.realpath(os.path.join(os.path.dirname(__file__), ".."))
EVALUATOR = os.path.join(REPO_ROOT, "scripts", "policy_evaluator.py")
FIXTURE_ROOT = os.path.join(REPO_ROOT, "tests", "contracts", "policy-envelope")
SCHEMA = os.path.join(REPO_ROOT, "schemas", "policy-envelope-v1.schema.json")


def load(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def evaluate(case_dir, policy_name, change_name):
    command = [
        sys.executable,
        EVALUATOR,
        "--policy",
        os.path.join(case_dir, policy_name),
        "--change",
        os.path.join(case_dir, change_name),
    ]
    completed = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return completed.returncode, completed.stdout


def check_schema_agreement():
    """Fail when the hand-written validator and the published schema drift.

    Nothing executes the JSON Schema, so without this the two can disagree
    silently about which fields a v1 envelope may carry.
    """

    sys.path.insert(0, os.path.join(REPO_ROOT, "scripts"))
    import policy_evaluator

    schema = load(SCHEMA)
    failures = []
    if set(schema["required"]) != policy_evaluator.POLICY_REQUIRED:
        failures.append("schema required fields differ from POLICY_REQUIRED")
    known = policy_evaluator.POLICY_REQUIRED | policy_evaluator.POLICY_OPTIONAL
    if set(schema["properties"]) != known:
        failures.append("schema properties differ from POLICY_REQUIRED|POLICY_OPTIONAL")

    item = schema["properties"]["verification"]["items"]
    if set(item["properties"]) != {"name", "command", "timeout_seconds"}:
        failures.append("schema verification item fields differ from the evaluator")
    if set(item["required"]) != {"name", "command"}:
        failures.append("schema verification required fields differ from the evaluator")
    return failures


def main():
    failures = check_schema_agreement()
    for name in sorted(os.listdir(FIXTURE_ROOT)):
        case_dir = os.path.join(FIXTURE_ROOT, name)
        case_path = os.path.join(case_dir, "case.json")
        if not os.path.isfile(case_path):
            continue
        case = load(case_path)
        expected = load(os.path.join(case_dir, case["expected"]))
        change_name = case["change"]
        code, stdout = evaluate(case_dir, case.get("policy", "policy.json"), change_name)
        try:
            actual = json.loads(stdout)
        except ValueError as error:
            failures.append("{}: invalid JSON output: {}".format(case["id"], error))
            continue
        if code != case["expected_exit_code"]:
            failures.append(
                "{}: expected exit {}, got {}".format(
                    case["id"], case["expected_exit_code"], code
                )
            )
        if actual != expected:
            failures.append(
                "{}: expected {}, got {}".format(case["id"], expected, actual)
            )

        # A widening fixture is only meaningful if the executor's copy really
        # would have authorized the change. Evaluate it too, so the case cannot
        # decay into an ordinary scope violation without anyone noticing.
        untrusted_name = case.get("untrusted_task_policy")
        if untrusted_name:
            untrusted_code, untrusted_stdout = evaluate(case_dir, untrusted_name, change_name)
            if untrusted_code == case["expected_exit_code"]:
                failures.append(
                    "{}: untrusted task-branch policy produces the same verdict as the "
                    "authoritative one, so the fixture proves nothing".format(case["id"])
                )
            if json.loads(untrusted_stdout)["result"] != "pass":
                failures.append(
                    "{}: untrusted task-branch policy must authorize the change it "
                    "tries to widen".format(case["id"])
                )

    if failures:
        for failure in failures:
            print("[FAIL] {}".format(failure), file=sys.stderr)
        return 1
    print("[PASS] contract_policy_envelope")
    return 0


if __name__ == "__main__":
    sys.exit(main())
