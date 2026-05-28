# Agent Loop Architecture: Claude Code vs Codex CLI

This document captures key findings on how Claude Code and Codex CLI implement their agent loops,
and what those differences mean for wtcraft users who orchestrate both.

> Researched May 2026 via web search, as both tools shipped significant changes after August 2025.

---

## Model Identification

**This session (branch `claude/cloudcoderevolvecri-agent-arch-gCoem`) runs on `claude-sonnet-4-6`.**

The user's guess of Sonnet 4.5 was close — 4.5 was the dominant daily driver through late 2025
($3/$15 per M tokens, released September 2025). Sonnet 4.6 replaced it as the default in
February 2026. As of May 2026:

| Alias | Resolves to |
|---|---|
| `sonnet` on Anthropic API / AWS Bedrock | `claude-sonnet-4-6` |
| `opus` | `claude-opus-4-7` |
| Codex CLI default (reasoning tasks) | `o3` |
| Codex CLI default (non-reasoning tasks) | `gpt-4o` |

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
┌───────────────────┐
│  Responses API    │◄──────────────┐
│  (HTTP, o3/gpt4o) │               │
└──────┬────────────┘               │
       │  tool call                 │
       └──► execute ──► result ─────┘
       │
       └── final answer ──► user
```

### Key characteristics

- **Sequential tool execution**: one tool call per iteration (no batching within a turn)
- **Responses API routing**: adds an HTTP round-trip through OpenAI's orchestration layer per iteration
- **o3 reasoning overhead**: o3 "thinks" before each action — stronger reasoning but higher latency per step
- **Stateless requests**: designed for Zero Data Retention compliance; no server-side state between calls
- **Prompt caching**: strategic caching ensures linear (not quadratic) token cost as context grows
- **Context compaction**: automatic window management for conversations spanning hundreds of iterations

---

## Side-by-Side Comparison

| Dimension | Claude Code | Codex CLI |
|---|---|---|
| Default model | `claude-sonnet-4-6` | `o3` / `gpt-4o` |
| Tool calls per turn | Parallel (multiple) | Sequential (one at a time) |
| API routing | Direct loop | Via Responses API |
| Reasoning overhead | Embedded in Sonnet/Opus | Explicit o3 think-step |
| Permission model | 7-mode + ML classifier | Sandbox-based isolation |
| Context management | 5-layer compaction | Automatic window compaction |
| Extensibility | MCP / skills / hooks / plugins | MCP / shell tools |
| Session storage | Append-oriented | Stateless (ZDR) |

---

## Implications for wtcraft

### Task contract design

- **Claude Code executors** benefit from broad file lists in `## Scope` — parallel reads mean
  they gather context in one turn. No need to sequence read-only steps.
- **Codex CLI executors** benefit from explicit step ordering in `## Steps` — each tool call
  is a round-trip, so a clear sequence reduces wasted iterations.

### Speed expectations

Perceived speed differences come from two compounding sources:
1. Parallel tool calls (Claude Code) vs sequential calls (Codex CLI)
2. Reasoning model latency (o3 thinks before acting; Sonnet does not)

For multi-file tasks, Claude Code will generally feel 2–4× faster even at similar token speeds.

### Role split recommendation

| Role | Preferred agent |
|---|---|
| Planner (architectural decisions) | Claude Code (Opus) or Codex CLI (o3) |
| Executor (multi-file edits) | Claude Code (Sonnet 4.6) — parallel tool calls |
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
- [Claude Sonnet 4.6 Specs — claudefa.st](https://claudefa.st/blog/models/claude-sonnet-4-6)
- [Anthropic Model Overview](https://platform.claude.com/docs/en/about-claude/models/overview)
