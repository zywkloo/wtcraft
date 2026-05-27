"""
wtcraft cost — per-branch Claude Code token usage and estimated cost.

Reads ~/.claude/projects/**/*.jsonl, aggregates assistant turns by
gitBranch, and prints a table. By default shows only branches visible
in the current repo's worktrees; --all shows every branch on record.
"""

import collections
import json
import pathlib
import subprocess
import sys

# Per-million-token USD pricing, mid-2026 estimates.
# Update when Anthropic revises rates.
_PRICING = {
    "claude-sonnet-4-6": {"input": 3.0,  "output": 15.0, "cache_read": 0.30, "cache_write": 3.75},
    "claude-opus-4-6":   {"input": 15.0, "output": 75.0, "cache_read": 1.50, "cache_write": 18.75},
    "claude-opus-4-7":   {"input": 15.0, "output": 75.0, "cache_read": 1.50, "cache_write": 18.75},
    "claude-haiku-4-5":  {"input": 0.8,  "output": 4.0,  "cache_read": 0.08, "cache_write": 1.0},
}
_DEFAULT_PRICING = {"input": 3.0, "output": 15.0, "cache_read": 0.30, "cache_write": 3.75}


def _cost_usd(usage, model):
    p = _PRICING.get(model, _DEFAULT_PRICING)
    m = 1_000_000
    return (
        usage.get("input_tokens", 0)                  * p["input"]       / m
        + usage.get("output_tokens", 0)               * p["output"]      / m
        + usage.get("cache_read_input_tokens", 0)     * p["cache_read"]  / m
        + usage.get("cache_creation_input_tokens", 0) * p["cache_write"] / m
    )


def _aggregate_claude_sessions():
    projects_dir = pathlib.Path.home() / ".claude" / "projects"
    by_branch = collections.defaultdict(lambda: {
        "input": 0, "output": 0, "cache_read": 0, "cache_write": 0,
        "cost_usd": 0.0, "turns": 0,
    })
    if not projects_dir.is_dir():
        return by_branch
    for jsonl in projects_dir.rglob("*.jsonl"):
        try:
            with open(jsonl, errors="ignore") as f:
                for line in f:
                    try:
                        obj = json.loads(line)
                    except Exception:
                        continue
                    if obj.get("type") != "assistant":
                        continue
                    usage = obj.get("message", {}).get("usage")
                    if not usage:
                        continue
                    branch = obj.get("gitBranch") or "_no_branch"
                    model = obj.get("message", {}).get("model", "")
                    b = by_branch[branch]
                    b["input"]       += usage.get("input_tokens", 0)
                    b["output"]      += usage.get("output_tokens", 0)
                    b["cache_read"]  += usage.get("cache_read_input_tokens", 0)
                    b["cache_write"] += usage.get("cache_creation_input_tokens", 0)
                    b["cost_usd"]    += _cost_usd(usage, model)
                    b["turns"]       += 1
        except OSError:
            continue
    return by_branch


def _git_worktree_branches(repo_root):
    try:
        out = subprocess.check_output(
            ["git", "-C", repo_root, "worktree", "list", "--porcelain"],
            stderr=subprocess.DEVNULL,
        ).decode()
    except Exception:
        return []
    return [
        line[len("branch refs/heads/"):]
        for line in out.splitlines()
        if line.startswith("branch refs/heads/")
    ]


def _current_branch(repo_root):
    try:
        return subprocess.check_output(
            ["git", "-C", repo_root, "rev-parse", "--abbrev-ref", "HEAD"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
    except Exception:
        return ""


def _git_repo_root():
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
    except Exception:
        return ""


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    if "--help" in argv or "-h" in argv:
        print("wtcraft cost [--all]\n")
        print("  Show Claude Code token usage and estimated cost per branch.")
        print("  Default: branches visible in the current repo's worktrees.")
        print("  --all    Show every branch recorded in Claude Code sessions.")
        return 0

    show_all = "--all" in argv
    repo_root = _git_repo_root()

    data = _aggregate_claude_sessions()
    if not data:
        print("No Claude Code session data found (~/.claude/projects/).")
        return 0

    if show_all or not repo_root:
        visible = sorted(data.keys(), key=lambda b: -data[b]["cost_usd"])
    else:
        wt_branches = set(_git_worktree_branches(repo_root))
        cur = _current_branch(repo_root)
        if cur:
            wt_branches.add(cur)
        visible = [
            b for b in sorted(data.keys(), key=lambda b: -data[b]["cost_usd"])
            if b in wt_branches
        ]
        if not visible:
            print("No Claude Code cost data for active worktree branches.")
            print("Tip: use `wtcraft cost --all` to see every recorded branch.")
            return 0

    HDR = "{:<45} {:>5}  {:>9}  {:>9}  {:>10}  {:>9}"
    ROW = "{:<45} {:>5}  {:>9,}  {:>9,}  {:>10,}  ${:>8.4f}"
    print(HDR.format("BRANCH", "TURNS", "IN", "OUT", "CACHE_R", "COST_USD"))
    print("-" * 95)
    total_cost = 0.0
    for b in visible:
        d = data[b]
        print(ROW.format(b, d["turns"], d["input"], d["output"], d["cache_read"], d["cost_usd"]))
        total_cost += d["cost_usd"]
    if len(visible) > 1:
        print("-" * 95)
        print("{:<45} {:>5}  {:>9}  {:>9}  {:>10}  ${:>8.4f}".format(
            "TOTAL", "", "", "", "", total_cost,
        ))
    return 0


if __name__ == "__main__":
    sys.exit(main())
