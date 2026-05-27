# Token Budget — Positioning and User Narratives

## The Problem This Document Addresses

Most "token budget" tooling in the npm ecosystem answers one question: *how much did I spend?*

`wtcraft` answers a different question: *why did I spend so much, and how do I not repeat it?*

This document covers:
1. The existing market landscape for token budget tooling
2. Two primary user narratives that drive `wtcraft`'s design
3. `wtcraft`'s differentiated position across those layers

---

## Market Landscape

### Category 1 — API-Level Budget Controls

**Anthropic Task Budget API** (Claude Opus 4.7, public beta, `task-budgets-2026-03-13` header)

A `task_budget` field injected server-side into agentic loops. Claude sees a token countdown and self-regulates toward graceful completion. Advisory (soft limit), not enforced — must combine with `max_tokens` for a hard cap.

Key limitations: Opus 4.7 only; not supported on Claude Code or Antigravity surfaces.

---

### Category 2 — Token Counting and Cost Observability

**llm-token-tracker** ([npm](https://www.npmjs.com/package/llm-token-tracker))

One-line client wrapper that intercepts API calls and counts input/output tokens across OpenAI, Claude, and Gemini. Supports per-user session accounting, MCP server mode, and visual progress bars against a 190k default budget. Real-time cost dashboards.

**CodeBurn** ([GitHub](https://github.com/getagentseal/codeburn))

Local TUI dashboard that reads session data from 25 AI coding tools (Claude Code, Codex, Antigravity CLI, Cursor, Cline, and more). Classifies tasks into 13 categories via deterministic pattern matching, tracks one-shot rates and retry cycles, correlates sessions with git commits (productive vs reverted vs abandoned), and surfaces copy-paste CLAUDE.md fixes. No API key or proxy required.

---

### Category 3 — Context Volume Auditing

**context-budget** (everything-claude-code skill)

A Claude Code skill that scans all loaded components in a session and reports token overhead with actionable trim recommendations. Single-shot analysis, not a continuous workflow control.

---

### Category 4 — Workflow Scaffolders with Worktree Support

**claude-workflow** ([npm](https://www.npmjs.com/package/claude-workflow))

Scaffolds Claude Code configs, task management, and optional worktree workflows. Adds structure around parallel agents with isolation via git worktrees but does not define an explicit task contract or handoff protocol.

**agenttools/worktree** ([GitHub](https://github.com/agenttools/worktree))

CLI for managing git worktrees with GitHub Issues and Claude Code integration. Auto-loads context, manages tmux sessions, supports multiple Claude workers. Tightly coupled to GitHub and Claude only.

---

### Where Every Existing Tool Falls Short

| Dimension | Existing tools | wtcraft |
|---|---|---|
| Layer of intervention | Token counting / API-level hint | **Task architecture** |
| Timing | After the fact or per-request | **Before the agent starts** |
| Context pollution | No solution | Worktree isolation per task |
| Wasted direction | Not tracked | Scope + Off-limits fields |
| Multi-tool compatibility | Single provider or tightly coupled | Claude + Codex + Antigravity |
| Platform dependency | API key / proxy / account | Zero — git + shell only |

The gap `wtcraft` fills: **architectural-level token conservation through task contracts and explicit handoff protocol.**

---

## User Narratives

### Narrative 1 — All-Free-Tier Multi-Agent User

**Tool stack (as of mid-2026):**

| Tool | Free access | Key constraint |
|---|---|---|
| Claude.ai / Claude Code | Chat: ~40 messages/day; Claude Code: not on free tier | CLI requires Pro or API credits |
| Codex (ChatGPT Free + CLI) | Promotional trial access; limited rolling window | Not a stable long-term free tier |
| Antigravity free | Originally 250 req/day → cut to ~20 req/day by Dec 2025 | Google has not committed to a permanent free offering |

**The core pain:**

Every agent session is a scarce resource. A free-tier user running three tools has roughly 20–40 usable agentic operations per day across the stack. A single poorly-bounded task — one where the agent reads irrelevant files, iterates in the wrong direction, or hands off to a second agent with a polluted context — can consume a day's quota.

**What free-tier users need:**

- Zero-waste context: agents must enter each session with a focused, bounded scope
- Correct-direction guarantee: scope and off-limits defined before the agent starts, so retries are avoided
- Intelligent sequencing: shared-file tasks must be serialized; only truly independent tasks can consume parallel quota
- Cross-tool contract: the same task file must be readable by Claude Code, Codex CLI, and Antigravity CLI — no per-tool reformatting

**How wtcraft addresses this:**

- `.worktree-task.md` defines Scope and Off-limits before agent invocation — wasted tokens from wrong-direction work are cut at the source
- `wtcraft check` verifies file boundaries before any agent touches anything
- DAG guidance in the planner role serializes shared-file tasks automatically
- The task contract format is plain Markdown — model-agnostic and tool-agnostic

---

### Narrative 2 — All-Lowest-Paid-Tier Multi-Agent User

**Tool stack (as of mid-2026):**

| Tool | Plan | Monthly cost | Key constraint |
|---|---|---|---|
| Claude Code | Claude Pro | $20/mo | ~45 prompts per 5-hour window; weekly cap; shared with Claude.ai chat |
| Codex (ChatGPT Plus) | Plus | $20/mo | Token-based billing per rolling window; Plus limits are notably lower than Pro ($200/mo) |
| Antigravity | AI Pro | $20/mo | Higher quota than free but still capped; credits at $0.01 top-up |
| **Total** | | **~$60/mo** | Each tool has independent rolling-window caps |

**The core pain:**

$60/month sounds like generous capacity, but each tool's rolling window is independent and shared with non-agentic usage. A developer who also uses Claude.ai for chat burns from the same bucket as Claude Code. Running two parallel agents on the same codebase multiplies spend without proportional output if tasks overlap in file ownership. PR review overload from multiple noisy branches adds human cost on top of token cost.

**What paid-tier users need:**

- Parallelism that pays off: spin up parallel agents only when file ownership is truly disjoint — otherwise serialize
- First-pass quality: a finisher that runs verification before reporting done, avoiding the "ship → agent fixes → ship again" loop
- Cross-tool normalization: one workflow primitive (the task contract) that works identically in Claude Code, Codex, and Antigravity CLI sessions
- Review consolidation: task boundaries tight enough that PRs are small and reviewable, not sprawling

**How wtcraft addresses this:**

- `wtcraft new` creates a worktree with a seeded contract; the planner role explicitly flags shared-file tasks as serialize-only
- `/finishwt` runs verification gates before the branch is considered done — catching failures inside the agent session rather than at PR review
- The four-role model (planner → executor → verifier → finisher) reduces round-trips: each role has one job and a clear exit condition
- The task contract format is the same Markdown file regardless of which agent CLI reads it

---

## wtcraft's Layer Position

Three layers of the multi-agent token budget stack:

```
Layer 3 — Observability
  llm-token-tracker, CodeBurn, context-budget
  (measure what was spent)

Layer 2 — Architecture  ← wtcraft
  Task contracts, handoff protocol, scope enforcement
  (prevent spend at the source)

Layer 1 — Infrastructure
  git worktrees, bash, agent CLIs
  (execution substrate)
```

`wtcraft` does not compete with Layer 3 tools. They are complementary: CodeBurn can show you how much a session cost; `wtcraft` is why the session was bounded enough to cost less in the first place.

---

## Feature Priority by User Narrative

| Feature | Free-tier user | Paid-tier user |
|---|---|---|
| Scope + Off-limits in task contract | Critical | Critical |
| DAG sequencing guidance (planner role) | Critical — quota is scarce | Important — prevents parallel waste |
| Cross-tool contract format (Claude/Codex/Antigravity) | Very important | Very important |
| `wtcraft check` boundary enforcement | Critical | Important |
| Verification gates (`wtcraft verify`, `/finishwt`) | Important | Critical — reduces retry loops |
| Token usage per-worktree summary (`wtcraft status`) | Future | Nice-to-have |
| Antigravity CLI integration (hooks, skills) | Future | Future |
| Task budget field in `.worktree-task.md` (Opus 4.7 API) | Out of scope for free tier | Future for paid tier |

---

## Sources and References

- [Anthropic Task Budget API docs](https://platform.claude.com/docs/en/build-with-claude/task-budgets)
- [llm-token-tracker — GitHub](https://github.com/wn01011/llm-token-tracker)
- [CodeBurn — GitHub](https://github.com/getagentseal/codeburn)
- [context-budget skill](https://www.claudepluginhub.com/skills/usernametron-everything-claude-code/context-budget)
- [Claude Code pricing 2026](https://www.howdoiuseai.com/blog/2026-04-16-claude-code-pricing-2026-plans-costs-and-free-tier)
- [Codex pricing 2026](https://uibakery.io/blog/openai-codex-pricing)
- [Google Antigravity 2.0 launch — MarkTechPost](https://www.marktechpost.com/2026/05/19/google-launches-antigravity-2-0-at-i-o-2026-a-standalone-agent-first-platform-with-cli-sdk-managed-execution-and-enterprise-support/)
- [Google Antigravity pricing 2026](https://vibecoding.app/blog/google-antigravity-pricing-2026)
