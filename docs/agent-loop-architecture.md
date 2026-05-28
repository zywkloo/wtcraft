# Agent Loop Architecture: Claude Code vs Codex (CLI + Cloud)

This document captures key findings on how Claude Code, Codex CLI, and Codex Cloud implement
their agent loops, and what those differences mean for wtcraft users who orchestrate both.

> Researched May 2026 via web search, as all three tools shipped significant changes after August 2025.

---

## Model Identification

**This session (branch `claude/cloudcoderevolvecri-agent-arch-gCoem`) runs on `claude-sonnet-4-6`.**

The user's guess of Sonnet 4.5 was close — 4.5 was the dominant daily driver through late 2025
($3/$15 per M tokens, released September 2025). Sonnet 4.6 replaced it as the default in
February 2026. As of May 2026:

| Alias / surface | Resolves to (May 2026) |
|---|---|
| `sonnet` on Anthropic API / AWS Bedrock | `claude-sonnet-4-6` |
| `opus` | `claude-opus-4-7` |
| Codex CLI — ChatGPT auth (Plus/Pro/Business) | `gpt-5.5` (default, switchable) |
| Codex CLI — API key | `gpt-5.2-codex` (GPT-5.5 not yet unlocked via API key) |
| Codex Cloud — all plans | `gpt-5.5` (locked, not user-switchable) |

**Note on history:** the original Codex agent (2025) ran on `codex-1`, an o3 fine-tune optimised
for software engineering. o3 and gpt-4o are no longer the defaults — the lineup has moved entirely
to the GPT-5.x series.

---

## Claude Code Agent Loop

**Core pattern:** a single-threaded master `while`-loop — call model, run tools, repeat.
The loop terminates when the model produces a plain-text response with no tool calls.

```
user input
    │
    ▼
┌─────────────┐
│  model call │◄──────────────────┐
└──────┬──────┘                   │
       │  tool calls?             │
       ├─yes──► run tools ────────┘
       └─no───► return to user
```

### What lives inside the loop (1.6% of codebase)

- Model call
- Tool dispatch

### What lives outside the loop (98.4% of codebase — deterministic infrastructure)

- **Permission system**: 7 modes + ML-based classifier for auto-allow/deny decisions
- **Context compaction**: 5-layer pipeline (summarize, prune, compress, cache, reload)
- **Extensibility**: MCP servers, plugins, skills, hooks
- **Subagent delegation**: spawning and orchestrating child agents for parallel subtasks
- **Session storage**: append-oriented (not overwrite), enabling replay and inspection

### Parallelism within a turn

Claude Code issues **multiple tool calls in a single model response** when they are independent.
A single reply can contain parallel `Bash` + `Read` calls — all execute concurrently before
the next model call. This compounds into significant wall-clock speedup on multi-file tasks.

---

## Codex CLI Agent Loop

**Core pattern:** iterative cycle through user input → model → tool execution → repeat,
mediated by OpenAI's Responses API.

```
user input
    │
    ▼
┌──────────────────────┐
│   Responses API      │◄──────────────┐
│  (HTTP, GPT-5.x)     │               │
└──────┬───────────────┘               │
       │  tool call                    │
       └──► execute ──► result ────────┘
       │
       └── final answer ──► user
```

### Key characteristics

- **Sequential tool execution**: one tool call per iteration (no batching within a turn)
- **Responses API routing**: adds an HTTP round-trip through OpenAI's orchestration layer per iteration
- **Adaptive reasoning**: GPT-5.x uses adjustable reasoning levels (`xhigh` for correctness-critical
  tasks, lower for speed) — no longer a fixed "think before every step" penalty like o3
- **Stateless requests**: designed for Zero Data Retention compliance; no server-side state between calls
- **Prompt caching**: strategic caching ensures linear (not quadratic) token cost as context grows
- **Context compaction**: automatic window management for conversations spanning hundreds of iterations

---

## Codex Cloud Agent Loop

Codex Cloud is a fundamentally different execution model from the CLI — it is an **async,
sandboxed cloud agent**, not a local interactive loop.

```
user submits task (ChatGPT / API)
    │
    ▼
┌─────────────────────────────────┐
│  Cloud sandbox (GitHub clone)   │
│  GPT-5.5 · xhigh reasoning      │
│  write → test → iterate → PR    │
└──────────────┬──────────────────┘
               │  async result
               ▼
         pull request opened
```

### Key characteristics

- **Model**: `gpt-5.5`, locked — users cannot switch models for cloud tasks
- **Reasoning level**: `xhigh` by default — the agent reasons deeply before each action because
  there is no human in the loop to catch mistakes mid-task
- **Execution environment**: isolated cloud sandbox; clones your GitHub repo, runs tests,
  iterates on failures, opens a PR — fully unattended
- **No local access**: cannot reach local databases, private infrastructure, or services
  outside the authorized repository
- **Async / fire-and-forget**: you stack tasks and come back to results; not a live conversation
- **Model not switchable**: unlike the CLI, Codex Cloud offers no model picker

---

## Side-by-Side Comparison

| Dimension | Claude Code | Codex CLI | Codex Cloud |
|---|---|---|---|
| Default model | `claude-sonnet-4-6` | `gpt-5.5` (ChatGPT auth) / `gpt-5.2-codex` (API key) | `gpt-5.5` (locked) |
| Model switchable | Yes (Sonnet / Opus) | Yes | No |
| Tool calls per turn | Parallel (multiple) | Sequential (one at a time) | Sequential in sandbox |
| Execution mode | Local, interactive | Local, interactive | Cloud, async / unattended |
| API routing | Direct loop | Via Responses API | Cloud sandbox + Responses API |
| Reasoning | Sonnet inline / Opus adaptive | GPT-5.x adaptive (adjustable level) | GPT-5.5 xhigh (fixed, no human fallback) |
| Permission model | 7-mode + ML classifier | Sandbox-based isolation | Isolated cloud sandbox |
| Local env access | Full (files, DB, secrets) | Full | GitHub repo only |
| Context management | 5-layer compaction | Automatic window compaction | Automatic window compaction |
| Extensibility | MCP / skills / hooks / plugins | MCP / shell tools | MCP (limited) |
| Session storage | Append-oriented | Stateless (ZDR) | Stateless (ZDR) |
| Output | In-terminal edits | In-terminal edits | Pull request |

---

## Implications for wtcraft

### Task contract design

- **Claude Code executors** benefit from broad file lists in `## Scope` — parallel reads mean
  they gather context in one turn. No need to sequence read-only steps.
- **Codex CLI executors** benefit from explicit step ordering in `## Steps` — each tool call
  is a round-trip, so a clear sequence reduces wasted iterations.

### Speed expectations

Perceived speed differences come from two compounding sources:
1. Parallel tool calls (Claude Code) vs sequential calls (Codex CLI / Cloud)
2. Reasoning level: Codex Cloud locks to `xhigh` — deepest reasoning, highest latency per step;
   Codex CLI lets you tune the level; Claude Code's Sonnet is fast by default, Opus adds
   adaptive thinking only when needed

For interactive multi-file tasks, Claude Code will generally feel 2–4× faster.
For unattended bulk tasks (adding tests, refactoring isolated modules), Codex Cloud wins on
throughput because you can stack tasks asynchronously.

### Role split recommendation

| Role | Preferred agent |
|---|---|
| Planner (architectural decisions) | Claude Code (Opus 4.7) or Codex CLI (GPT-5.5, xhigh) |
| Executor (multi-file edits, interactive) | Claude Code (Sonnet 4.6) — parallel tool calls |
| Bulk / parallelisable background tasks | Codex Cloud — async, fire-and-forget, opens PRs |
| Finisher / reviewer | Either |

### Worktree boundary enforcement

Both agents respect explicit `## Off-limits` constraints when the task contract is read upfront.
Claude Code reads the contract faster (parallel file loads); Codex CLI reads it more methodically.
Either way, `wtcraft check` is the authoritative gate — do not rely on agent self-policing alone.

---

## Sources

- [How Claude Code Works — Claude Code Docs](https://code.claude.com/docs/en/how-claude-code-works)
- [Claude Code Architecture Explained — DEV Community](https://dev.to/brooks_wilson_36fbefbbae4/claude-code-architecture-explained-agent-loop-tool-system-and-permission-model-rust-rewrite-41b2)
- [Claude Code Agent Architecture — ZenML LLMOps Database](https://www.zenml.io/llmops-database/claude-code-agent-architecture-single-threaded-master-loop-for-autonomous-coding)
- [Unrolling the Codex Agent Loop — OpenAI](https://openai.com/index/unrolling-the-codex-agent-loop/)
- [Codex CLI Architecture — ZenML LLMOps Database](https://www.zenml.io/llmops-database/building-production-ready-ai-agents-openai-codex-cli-architecture-and-agent-loop-design)
- [Introducing GPT-5.2-Codex — OpenAI](https://openai.com/index/introducing-gpt-5-2-codex/)
- [Introducing GPT-5.3-Codex — OpenAI](https://openai.com/index/introducing-gpt-5-3-codex/)
- [GPT-5.3-Codex now base model for Copilot — GitHub Changelog](https://github.blog/changelog/2026-05-17-gpt-5-3-codex-is-now-the-base-model-for-copilot-business-and-enterprise/)
- [Models — Codex Developer Docs](https://developers.openai.com/codex/models)
- [Web (Cloud) — Codex Developer Docs](https://developers.openai.com/codex/cloud)
- [Codex CLI Complete Guide 2026 — codegateway.dev](https://www.codegateway.dev/en/blog/openai-codex-cli-complete-guide-2026)
- [Claude Sonnet 4.6 Specs — claudefa.st](https://claudefa.st/blog/models/claude-sonnet-4-6)
- [Claude Opus 4.7 vs Sonnet 4.6 — BenchLM](https://benchlm.ai/compare/claude-opus-4-7-vs-claude-sonnet-4-6)
- [Anthropic Model Overview](https://platform.claude.com/docs/en/about-claude/models/overview)
