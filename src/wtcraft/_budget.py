#!/usr/bin/env python3
"""
wtcraft Budget & Token Tracker (Token Budget AI Assistant)

Parses local Claude session logs, projects token usage and spending,
and runs rule-based velocity, cache, and routing diagnostics.
"""

import os
import sys
import glob
import json
import subprocess
from datetime import datetime, timedelta

# Sonnet 3.5 pricing per million tokens
PRICE_INPUT_STANDARD = 3.00
PRICE_INPUT_CACHE_WRITE = 3.75
PRICE_INPUT_CACHE_READ = 0.30
PRICE_OUTPUT = 15.00

# Base context size (tokens) representing Claude system prompt, instructions, and tools
BASE_CONTEXT_TOKENS = 6000

def get_git_root():
    try:
        res = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except Exception:
        curr = os.getcwd()
        while curr != os.path.dirname(curr):
            if os.path.isdir(os.path.join(curr, ".git")):
                return curr
            curr = os.path.dirname(curr)
        return os.getcwd()

def get_claude_project_dir(git_root):
    slug = git_root.replace("/", "-")
    return os.path.expanduser(f"~/.claude/projects/{slug}")

def parse_timestamp(ts_str):
    if ts_str.endswith("Z"):
        ts_str = ts_str[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(ts_str)
    except Exception:
        return datetime.utcnow()

def est_tokens(text):
    # Standard rule of thumb: 1 token ≈ 4 characters
    return len(text) // 4

def get_entry_text(entry):
    text = ""
    if "message" in entry:
        msg = entry["message"]
        if isinstance(msg, str):
            text += msg
        elif isinstance(msg, dict) or isinstance(msg, list):
            text += json.dumps(msg)
    if "toolUseResult" in entry:
        res = entry["toolUseResult"]
        if isinstance(res, str):
            text += res
        elif isinstance(res, dict) or isinstance(res, list):
            text += json.dumps(res)
    if "attachment" in entry:
        att = entry["attachment"]
        if isinstance(att, str):
            text += att
        elif isinstance(att, dict) or isinstance(att, list):
            text += json.dumps(att)
    return text

class SessionStats:
    def __init__(self, session_id, branch):
        self.session_id = session_id
        self.branch = branch
        self.start_time = None
        self.end_time = None
        self.duration_seconds = 0
        self.input_write_tokens = 0
        self.input_read_tokens = 0
        self.output_tokens = 0
        self.turns_count = 0
        self.cost = 0.0
        self.cache_efficiency = 0.0

def process_session_file(filepath):
    session_id = os.path.basename(filepath).replace(".jsonl", "")
    entries = []
    
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
                if "timestamp" in d:
                    entries.append(d)
            except Exception:
                pass
                
    if not entries:
        return None
        
    entries.sort(key=lambda x: x["timestamp"])
    
    # Try to extract the git branch from entries
    branch = "unknown"
    for e in entries:
        if "gitBranch" in e and e["gitBranch"]:
            branch = e["gitBranch"]
            break
            
    stats = SessionStats(session_id, branch)
    stats.start_time = parse_timestamp(entries[0]["timestamp"])
    stats.end_time = parse_timestamp(entries[-1]["timestamp"])
    stats.duration_seconds = max(1, (stats.end_time - stats.start_time).total_seconds())
    
    context_tokens = BASE_CONTEXT_TOKENS
    last_turn_time = None
    
    for entry in entries:
        e_type = entry.get("type")
        e_time = parse_timestamp(entry["timestamp"])
        
        entry_text = get_entry_text(entry)
        entry_tokens = est_tokens(entry_text)
        
        if e_type == "user":
            stats.turns_count += 1
            # Check for cache hit: if time between turns is < 5 minutes (300 seconds)
            is_cache_hit = False
            if last_turn_time is not None:
                time_diff = (e_time - last_turn_time).total_seconds()
                if time_diff < 300:
                    is_cache_hit = True
            
            if is_cache_hit:
                # Cache Read for the previous context
                read_toks = context_tokens
                write_toks = entry_tokens
                
                stats.input_read_tokens += read_toks
                stats.input_write_tokens += write_toks
                
                stats.cost += (read_toks * PRICE_INPUT_CACHE_READ) / 1_000_000
                stats.cost += (write_toks * PRICE_INPUT_CACHE_WRITE) / 1_000_000
            else:
                # Cache Miss: write the whole context + new message
                write_toks = context_tokens + entry_tokens
                
                stats.input_write_tokens += write_toks
                stats.cost += (write_toks * PRICE_INPUT_CACHE_WRITE) / 1_000_000
                
            context_tokens += entry_tokens
            last_turn_time = e_time
            
        elif e_type == "assistant":
            stats.output_tokens += entry_tokens
            stats.cost += (entry_tokens * PRICE_OUTPUT) / 1_000_000
            context_tokens += entry_tokens
            
        elif e_type == "attachment":
            context_tokens += entry_tokens
            
    total_input = stats.input_read_tokens + stats.input_write_tokens
    if total_input > 0:
        stats.cache_efficiency = (stats.input_read_tokens / total_input) * 100
        
    return stats

def get_budget_limits(git_root):
    limit = 2.00
    threshold = 0.80
    
    # Check environment variable override
    env_limit = os.environ.get("WTCRAFT_MAX_BUDGET")
    if env_limit:
        try:
            return float(env_limit), threshold
        except ValueError:
            pass
            
    # Try reading task files
    for filename in [".worktree-task.md", ".worktree-task.template.md"]:
        filepath = os.path.join(git_root, filename)
        if os.path.isfile(filepath):
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                    if content.startswith("---"):
                        parts = content.split("---")
                        if len(parts) >= 3:
                            fm = parts[1]
                            for line in fm.split("\n"):
                                line = line.strip()
                                if line.startswith("max_task_budget:"):
                                    limit = float(line.split(":", 1)[1].strip())
                                elif line.startswith("alert_threshold:"):
                                    threshold = float(line.split(":", 1)[1].strip())
            except Exception:
                pass
    return limit, threshold

def format_duration(seconds):
    if seconds < 60:
        return f"{int(seconds)}s"
    minutes = seconds // 60
    secs = seconds % 60
    if minutes < 60:
        return f"{int(minutes)}m {int(secs)}s"
    hours = minutes // 60
    mins = minutes % 60
    return f"{int(hours)}h {int(mins)}m"

def get_all_sessions(project_dir):
    if not os.path.isdir(project_dir):
        return []
    files = glob.glob(os.path.join(project_dir, "*.jsonl"))
    sessions = []
    for f in files:
        stats = process_session_file(f)
        if stats:
            sessions.append(stats)
    # Sort by end time desc (most recent first)
    sessions.sort(key=lambda x: x.end_time, reverse=True)
    return sessions

def run_git_diff_scope(git_root):
    # Estimate how many files are currently modified or declared in Scope
    try:
        res = subprocess.run(["git", "diff", "--name-only", "HEAD"], capture_output=True, text=True, check=True, cwd=git_root)
        files = [f for f in res.stdout.strip().split("\n") if f]
        return len(files)
    except Exception:
        return 0

def cmd_budget(args):
    # Parse CLI options
    days = 7
    detail = False
    
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--days" and i + 1 < len(args):
            try:
                days = int(args[i+1])
            except ValueError:
                pass
            i += 2
        elif arg == "--detail":
            detail = True
            i += 1
        else:
            i += 1
            
    git_root = get_git_root()
    proj_dir = get_claude_project_dir(git_root)
    sessions = get_all_sessions(proj_dir)
    
    cutoff = datetime.now() - timedelta(days=days)
    # Filter by days cutoff
    cutoff_utc = cutoff.replace(tzinfo=None)
    filtered_sessions = [s for s in sessions if s.end_time.replace(tzinfo=None) >= cutoff_utc]
    
    if not filtered_sessions:
        print(f"No active session logs found for this project in the last {days} days.")
        print(f"Project log folder: {proj_dir}")
        return
        
    print(f"\nwtcraft budget - Activity across last {days} days:")
    print("=" * 95)
    print(f"{'Session ID':<12} {'Branch':<25} {'Last Active':<19} {'Duration':<10} {'Cache Eff':<10} {'Spend (USD)':<10}")
    print("-" * 95)
    
    total_cost = 0.0
    total_in_w = 0
    total_in_r = 0
    total_out = 0
    
    for s in filtered_sessions:
        active_str = s.end_time.strftime("%Y-%m-%d %H:%M:%S")
        dur_str = format_duration(s.duration_seconds)
        eff_str = f"{s.cache_efficiency:.1f}%"
        cost_str = f"${s.cost:.4f}"
        
        sess_id_trunc = s.session_id[:8] + "..."
        branch_trunc = s.branch[:23] + "..." if len(s.branch) > 25 else s.branch
        
        print(f"{sess_id_trunc:<12} {branch_trunc:<25} {active_str:<19} {dur_str:<10} {eff_str:<10} {cost_str:<10}")
        
        total_cost += s.cost
        total_in_w += s.input_write_tokens
        total_in_r += s.input_read_tokens
        total_out += s.output_tokens
        
    print("-" * 95)
    print(f"{'TOTAL':<12} {'':<25} {'':<19} {'':<10} {'':<10} ${total_cost:.4f}")
    print("=" * 95)
    
    if detail:
        print("\nToken Usage Details:")
        print(f"  Input Tokens (Cache Write / Miss): {total_in_w:,}")
        print(f"  Input Tokens (Cache Read / Hit):   {total_in_r:,}")
        print(f"  Output Tokens:                     {total_out:,}")
        print(f"  Total API Interactions:            {sum(s.turns_count for s in filtered_sessions)}")
        
    # Heuristics tips
    limits, threshold = get_budget_limits(git_root)
    last_24h_sessions = [s for s in sessions if (datetime.now() - s.end_time.replace(tzinfo=None)).total_seconds() < 86400]
    cost_24h = sum(s.cost for s in last_24h_sessions)
    
    print("\nToken Budget AI Assistant Recommendations:")
    print("-" * 50)
    
    # 1. Velocity Diagnostic
    print(f"💡 Velocity Check: Daily budget consumed: ${cost_24h:.2f} / ${limits:.2f} limit.")
    if cost_24h >= limits * threshold:
        print(f"⚠️  [WARNING] High token spending velocity detected! Daily spend is at {cost_24h/limits*100:.1f}% of limits.")
        
    # 2. Cache Diagnostic (Active Session)
    active_s = filtered_sessions[0]
    if active_s.cache_efficiency < 40.0:
        print(f"📌 [TIP] Cache Efficiency is Low ({active_s.cache_efficiency:.1f}%):")
        print("    You are paying full price for prompt context. To enable Claude's prompt caching,")
        print("    avoid making minor edits to files outside of your target scope to prevent context invalidation.")
    else:
        print(f"✅ Cache Efficiency is healthy ({active_s.cache_efficiency:.1f}%).")
        
    # 3. Model Recommendation
    small_files = run_git_diff_scope(git_root)
    if small_files <= 2:
        print(f"📌 [TIP] Small task footprint detected ({small_files} modified file(s)):")
        print("    Consider running with Gemini 1.5 Flash to save up to ~$0.35 over Claude 3.5 Sonnet.")
    print()

def hook_new(branch_name):
    git_root = get_git_root()
    proj_dir = get_claude_project_dir(git_root)
    sessions = get_all_sessions(proj_dir)
    limits, threshold = get_budget_limits(git_root)
    
    last_24h_sessions = [s for s in sessions if (datetime.now() - s.end_time.replace(tzinfo=None)).total_seconds() < 86400]
    cost_24h = sum(s.cost for s in last_24h_sessions)
    
    print("\n[wtcraft budget hook-new]")
    print(f"  Daily budget consumed: ${cost_24h:.2f} / ${limits:.2f} limit.")
    if cost_24h >= limits * threshold:
        print(f"  ⚠️  [WARNING] Daily token spending velocity is high (${cost_24h:.2f}). Proceed with caution!")
        
    # Count scoping
    small_files = run_git_diff_scope(git_root)
    if small_files <= 2:
        print("  📌 [TIP] This task touches very few files. Consider running with Gemini 1.5 Flash to save costs.")
    print()

def hook_pre(wt_path):
    git_root = get_git_root()
    proj_dir = get_claude_project_dir(git_root)
    sessions = get_all_sessions(proj_dir)
    limits, threshold = get_budget_limits(git_root)
    
    if not sessions:
        return
        
    active_s = sessions[0]
    # Check if budget is near limit
    remaining = limits - active_s.cost
    
    print(f"\n[wtcraft budget hook-pre] Active Session: {active_s.session_id[:8]}... (Spend: ${active_s.cost:.2f} / ${limits:.2f})")
    
    if remaining <= 0:
        print("  ⚠️  [CRITICAL] Remaining task budget is completely EXHAUSTED! Please commit your changes and finish.")
    elif active_s.cost >= limits * threshold:
        print(f"  ⚠️  [WARNING] Session cost is at {active_s.cost/limits*100:.1f}% of limits! (${active_s.cost:.2f} consumed).")
        
    # Check burn rate
    if active_s.duration_seconds > 0:
        burn_rate_min = (active_s.cost / (active_s.duration_seconds / 60.0))
        if burn_rate_min > 0.15:
            # Steep burn-rate detected
            proj_exhaust_sec = int(remaining / (burn_rate_min / 60.0)) if remaining > 0 else 0
            if proj_exhaust_sec > 0:
                print(f"  ⚠️  [WARNING] High Token Burn-Rate Detected!")
                print(f"      At your current velocity (${burn_rate_min:.2f}/min), you are projected to exhaust your remaining ${remaining:.2f} budget in {proj_exhaust_sec} seconds.")
                print(f"      Consider committing current changes and restarting the session to compact history.")
    print()

def hook_post(wt_path):
    git_root = get_git_root()
    proj_dir = get_claude_project_dir(git_root)
    sessions = get_all_sessions(proj_dir)
    limits, threshold = get_budget_limits(git_root)
    
    if not sessions:
        return
        
    active_s = sessions[0]
    print(f"[wtcraft budget hook-post] Active Session: {active_s.session_id[:8]}... (Final Spend: ${active_s.cost:.2f} / ${limits:.2f})")
    
    if active_s.cache_efficiency < 40.0:
        print(f"  📌 [TIP] Cache Efficiency is Low ({active_s.cache_efficiency:.1f}%):")
        print("      To enable Claude's prompt caching, avoid making minor edits to files outside")
        print("      of your target scope to prevent context invalidation.")
    print()

def main():
    if len(sys.argv) < 2:
        print("Usage: _budget.py <command> [args...]")
        sys.exit(1)
        
    cmd = sys.argv[1]
    args = sys.argv[2:]
    
    if cmd == "budget":
        cmd_budget(args)
    elif cmd == "hook-new":
        branch = args[0] if args else "unknown"
        hook_new(branch)
    elif cmd == "hook-pre":
        wt_path = args[0] if args else "."
        hook_pre(wt_path)
    elif cmd == "hook-post":
        wt_path = args[0] if args else "."
        hook_post(wt_path)
    else:
        print(f"Unknown budget command: {cmd}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
