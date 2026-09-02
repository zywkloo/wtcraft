#!/usr/bin/env python3
"""Reference evaluator for wtcraft Policy Envelope v1.

This is an internal, source-checkout reference used by contract fixtures. It
does not install a public CLI command, execute verification commands, or fetch
from a Git host. A future CI adapter must supply trusted policy and changeset
facts, then preserve this evaluator's fail-closed verdict semantics.
"""

import argparse
import json
import re
import sys


POLICY_REQUIRED = {
    "schema_version",
    "policy_id",
    "task_id",
    "repository",
    "head_ref",
    "base_sha",
    "allowed_paths",
    "off_limits",
    "verification",
}
POLICY_OPTIONAL = {"valid_until"}
POLICY_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{2,127}$")
REPOSITORY_RE = re.compile(r"^[^/\s]+/[^/\s]+$")
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
RFC3339_RE = re.compile(
    r"^\d{4}-\d{2}-\d{2}[Tt]\d{2}:\d{2}:\d{2}(\.\d+)?([Zz]|[+-]\d{2}:\d{2})$"
)

HEAD_REF_PREFIX = "refs/heads/"
# git-check-ref-format(1): control characters, space, and these bytes are never
# legal in a ref component. Everything else, including non-ASCII, is legal.
REF_FORBIDDEN_RE = re.compile(r"[\x00-\x20\x7f~^:?*\[\\]")
# Shell wildcards other than `*` are rejected rather than reinterpreted, so a
# pattern can never mean something narrower in CI than it does locally.
UNSUPPORTED_GLOB_RE = re.compile(r"[?\[\]]")


class InvalidPolicy(ValueError):
    """The authoritative envelope is missing or does not satisfy v1."""


class InvalidChange(ValueError):
    """The supplied immutable pull-request facts are incomplete."""


def load_json(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def require_string(value, field, maximum=None):
    if not isinstance(value, str) or not value:
        raise InvalidPolicy("{} must be a non-empty string".format(field))
    if maximum is not None and len(value) > maximum:
        raise InvalidPolicy("{} exceeds {} characters".format(field, maximum))


def is_valid_head_ref(value):
    """Accept any git-legal `refs/heads/` branch name, including non-ASCII.

    A narrower ASCII-only rule would reject branch names that git and the Git
    host accept, which fails a legitimate task instead of an unauthorized one.
    """

    if not isinstance(value, str) or not value.startswith(HEAD_REF_PREFIX):
        return False
    name = value[len(HEAD_REF_PREFIX):]
    if not name or name.startswith("/") or name.endswith("/") or "//" in name:
        return False
    if name.endswith(".") or ".." in name or "@{" in name or name == "@":
        return False
    if REF_FORBIDDEN_RE.search(name):
        return False
    return not any(part.endswith(".lock") for part in name.split("/"))


def validate_path_pattern(value, field):
    require_string(value, field, 1024)
    if value.startswith("/"):
        raise InvalidPolicy("{} must be repository-relative".format(field))
    if ".." in value.split("/"):
        raise InvalidPolicy("{} must not contain parent traversal".format(field))
    if UNSUPPORTED_GLOB_RE.search(value):
        raise InvalidPolicy(
            "{} may only use `*` as a wildcard; `?` and `[]` are not supported "
            "and must be written as separate patterns".format(field)
        )


def validate_path_list(value, field, require_nonempty):
    if not isinstance(value, list):
        raise InvalidPolicy("{} must be an array".format(field))
    if require_nonempty and not value:
        raise InvalidPolicy("{} must not be empty".format(field))
    for item in value:
        validate_path_pattern(item, field)
    if len(value) != len(set(value)):
        raise InvalidPolicy("{} must not contain duplicates".format(field))


def validate_policy(policy):
    if not isinstance(policy, dict):
        raise InvalidPolicy("policy must be a JSON object")

    missing = POLICY_REQUIRED - set(policy)
    if missing:
        raise InvalidPolicy("policy is missing required fields: {}".format(
            ", ".join(sorted(missing))
        ))

    unknown = set(policy) - POLICY_REQUIRED - POLICY_OPTIONAL
    if unknown:
        raise InvalidPolicy("policy has unknown fields: {}".format(
            ", ".join(sorted(unknown))
        ))

    if type(policy["schema_version"]) is not int or policy["schema_version"] != 1:
        raise InvalidPolicy("schema_version must equal 1")
    require_string(policy["policy_id"], "policy_id", 128)
    if not POLICY_ID_RE.match(policy["policy_id"]):
        raise InvalidPolicy("policy_id has an invalid format")
    require_string(policy["task_id"], "task_id", 256)
    require_string(policy["repository"], "repository")
    if not REPOSITORY_RE.match(policy["repository"]):
        raise InvalidPolicy("repository must have owner/name format")
    require_string(policy["head_ref"], "head_ref")
    if not is_valid_head_ref(policy["head_ref"]):
        raise InvalidPolicy("head_ref must be a git-legal refs/heads/ branch")
    require_string(policy["base_sha"], "base_sha")
    if not SHA_RE.match(policy["base_sha"]):
        raise InvalidPolicy("base_sha must be a lowercase 40-character SHA")

    validate_path_list(policy["allowed_paths"], "allowed_paths", True)
    validate_path_list(policy["off_limits"], "off_limits", False)

    verification = policy["verification"]
    if not isinstance(verification, list) or not verification:
        raise InvalidPolicy("verification must be a non-empty array")
    for index, item in enumerate(verification):
        field = "verification[{}]".format(index)
        if not isinstance(item, dict):
            raise InvalidPolicy("{} must be an object".format(field))
        unknown_item = set(item) - {"name", "command", "timeout_seconds"}
        if unknown_item:
            raise InvalidPolicy("{} has unknown fields: {}".format(
                field, ", ".join(sorted(unknown_item))
            ))
        if "name" not in item or "command" not in item:
            raise InvalidPolicy("{} requires name and command".format(field))
        require_string(item["name"], "{}.name".format(field), 128)
        require_string(item["command"], "{}.command".format(field), 4096)
        if "timeout_seconds" in item:
            timeout = item["timeout_seconds"]
            if type(timeout) is not int or not 1 <= timeout <= 3600:
                raise InvalidPolicy(
                    "{}.timeout_seconds must be an integer from 1 to 3600".format(field)
                )

    if "valid_until" in policy:
        require_string(policy["valid_until"], "valid_until")
        # Format is validated here so a malformed value fails closed. Expiry
        # itself needs a trusted clock and is enforced by the CI adapter.
        if not RFC3339_RE.match(policy["valid_until"]):
            raise InvalidPolicy("valid_until must be an RFC 3339 date-time")


def validate_change(change):
    if not isinstance(change, dict):
        raise InvalidChange("change facts must be a JSON object")
    required = {"repository", "head_ref", "merge_base_sha", "changed_files"}
    missing = required - set(change)
    if missing:
        raise InvalidChange("change facts are missing: {}".format(
            ", ".join(sorted(missing))
        ))
    if not isinstance(change["repository"], str) or not REPOSITORY_RE.match(change["repository"]):
        raise InvalidChange("change repository must have owner/name format")
    if not is_valid_head_ref(change["head_ref"]):
        raise InvalidChange("change head_ref must be a git-legal refs/heads/ branch")
    if not isinstance(change["merge_base_sha"], str) or not SHA_RE.match(change["merge_base_sha"]):
        raise InvalidChange("change merge_base_sha must be a lowercase 40-character SHA")
    if not isinstance(change["changed_files"], list):
        raise InvalidChange("change changed_files must be an array")
    for path in change["changed_files"]:
        if not isinstance(path, str) or not path or path.startswith("/"):
            raise InvalidChange("changed_files must contain repository-relative paths")
        if ".." in path.split("/"):
            raise InvalidChange("changed_files must not contain parent traversal")


def matches_path(path, pattern):
    """Match the existing wtcraft Scope/Off-limits semantics.

    A pattern without `*` is an exact path or directory prefix. A pattern with
    `*` uses the existing wtcraft matching semantics where it may match path
    separators. `?` and `[]` never reach this function: validate_path_pattern
    rejects them, because treating them literally here would make an
    `off_limits` rule match fewer paths in CI than `wtcraft check` matches
    locally.
    """

    if "*" not in pattern:
        prefix = pattern.rstrip("/")
        return path == prefix or path.startswith(prefix + "/")
    expression = "^" + re.escape(pattern).replace(r"\*", ".*") + "$"
    return re.match(expression, path) is not None


def verdict(policy, change):
    validate_policy(policy)
    validate_change(change)

    policy_id = policy["policy_id"]
    if change["repository"] != policy["repository"]:
        return {"result": "fail", "reason": "repository_mismatch", "policy_id": policy_id}
    if change["head_ref"] != policy["head_ref"]:
        return {"result": "fail", "reason": "head_ref_mismatch", "policy_id": policy_id}
    if change["merge_base_sha"] != policy["base_sha"]:
        return {"result": "fail", "reason": "stale_base", "policy_id": policy_id}

    violations = []
    for path in change["changed_files"]:
        allowed = any(matches_path(path, item) for item in policy["allowed_paths"])
        denied = any(matches_path(path, item) for item in policy["off_limits"])
        if not allowed or denied:
            violations.append(path)
    if violations:
        return {
            "result": "fail",
            "reason": "scope_violation",
            "policy_id": policy_id,
            "violations": violations,
        }
    return {"result": "pass", "reason": "authorized", "policy_id": policy_id}


def emit(value):
    json.dump(value, sys.stdout, separators=(",", ":"), sort_keys=True)
    sys.stdout.write("\n")


def main():
    parser = argparse.ArgumentParser(description="Evaluate a wtcraft Policy Envelope v1")
    parser.add_argument("--policy", required=True, help="authoritative policy-envelope JSON path")
    parser.add_argument("--change", required=True, help="immutable pull-request facts JSON path")
    args = parser.parse_args()

    try:
        policy = load_json(args.policy)
    except FileNotFoundError:
        emit({"result": "fail", "reason": "policy_not_found"})
        return 1
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print("invalid policy: {}".format(error), file=sys.stderr)
        emit({"result": "fail", "reason": "invalid_policy"})
        return 1

    try:
        change = load_json(args.change)
        result = verdict(policy, change)
    except InvalidPolicy as error:
        print("invalid policy: {}".format(error), file=sys.stderr)
        emit({"result": "fail", "reason": "invalid_policy"})
        return 1
    except (FileNotFoundError, OSError, ValueError, json.JSONDecodeError, InvalidChange) as error:
        print("invalid change facts: {}".format(error), file=sys.stderr)
        emit({"result": "fail", "reason": "invalid_change"})
        return 1

    emit(result)
    return 0 if result["result"] == "pass" else 2


if __name__ == "__main__":
    sys.exit(main())
