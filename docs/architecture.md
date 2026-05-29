# wtcraft Architecture

## What Every Modern Coding Agent Is Doing

Claude Code, Codex CLI, and Gemini CLI all implement the same core pattern:

```
LLM + Tool Runtime + Agent Loop + Context Compression + Permission Layer
```

The loop itself is simple:

```
while not done:
    observe()
    think()
    use_tools()     # read file, grep, run test, edit, spawn subagent, git diff
    inspect_result()
    decide_next_step()
```

This is not "user asks, AI answers." The agent drives itself. Tools are first-class actions, not outputs.

## Where Each Agent CLI Sits

| CLI | Internal loop style | Strength |
|---|---|---|
| Claude Code | Autonomous reasoning, subagents, self-compacting context | Long multi-step planning, autonomous engineer |
| Codex CLI | Harness-oriented, Responses API, deterministic tooling | Controlled orchestration, multi-surface (CLI/VSCode/cloud) |
| Gemini CLI | Large context window, `GEMINI.md` project context | Long-context tasks, free-tier executor |

All three converge on the same primitives underneath. The differences are in orchestration philosophy, not fundamental architecture.

## What wtcraft Adds

wtcraft does not implement an agent loop. It coordinates *across* agent loops:

```
     wtcraft
  (task graph · worktree isolation · scope contracts · budget routing)
         ↓               ↓               ↓
   Claude Code       Codex CLI       Gemini CLI
  (loop + tools)   (loop + tools)  (loop + tools)
         ↓               ↓               ↓
                  actual file edits
```

wtcraft is an **orchestrator of orchestrators**. Each inner agent is already an orchestrator with its own loop, tool runtime, and context manager. wtcraft handles what none of them address natively:

- **Which tasks go to which agent** — planner (Claude) → executor (Codex or Gemini) → finisher (Claude)
- **File ownership across agents** — `Scope` and `Off-limits` in `.worktree-task.md` prevent agents from stepping on each other
- **Context isolation** — each worktree = a fresh context for the inner agent; no cross-task pollution
- **Budget routing** — expensive tasks to capable models, bulk work to free-tier executors
- **Handoff contracts** — explicit `.worktree-task.md` replaces implicit "just do it" prompts

## How wtcraft Components Map to Inner-Loop Concepts

| Inner agent concept | wtcraft equivalent |
|---|---|
| Permission system / allowlist | `Scope` + `Off-limits` in `.worktree-task.md` |
| Context isolation | Git worktree per task (fresh working tree, no shared state) |
| Context compression | Not needed — worktrees are bounded and short-lived |
| Subagent spawning | `wtcraft new` creates an isolated worktree for a parallel sub-task |
| Tool boundary enforcement | `wtcraft check <worktree>` — verifies no out-of-scope file was touched |
| Completion gate | `wtcraft verify <worktree>` — runs the task's own verification commands |

## Key Takeaways

1. **The real value in agent tooling is the runtime, not the model.** Claude Code's leaked source surprised people not because of the model weights but because of the orchestration: TypeScript loop, tool runtime, permission system, memory compaction, subagent scheduler.

2. **Context isolation IS the product for multi-agent work.** Sharing one long context across agents creates pollution and collisions. wtcraft makes this irrelevant by giving each agent a bounded worktree.

3. **Scope contracts are a permission system at the coordination layer.** Claude Code enforces what shell commands can run. wtcraft enforces which files each agent can touch. Same concept, different layer.

4. **Autonomous inner loops need outer constraints.** Each inner loop (especially Claude Code) will try to expand scope when uncertain. The `Off-limits` section is what keeps the outer coordination contract intact against that pressure.

5. **Budget routing is a first-class architectural concern, not an afterthought.** Allocating expensive models to planning/finishing and cheap/free models to execution is a design decision, not a cost-saving hack.

6. **The industry has converged on the same primitives.** Every serious coding agent today is: LLM + tool runtime + agent loop + context manager + permission layer. wtcraft adds the missing coordination layer on top of that common foundation.
