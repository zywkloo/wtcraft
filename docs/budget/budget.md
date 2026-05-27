# wtcraft Budget & Token Tracker (Token Budget AI Assistant)

Positioning: **Control your agent API spending with git-native usage tracking.**

Solo developers orchestrating multiple coding agents face a common risk: **runaway API costs**. A loop-happy agent or a bloated context window can quietly consume $10–$50 in a single afternoon. 

`wtcraft` integrates a local, rule-based **Token Budget AI Assistant** designed to parse agent execution logs, project token burn rates, and recommend immediate cost-saving adjustments at every hook in your workflow.

---

## 1. Hybrid Configuration Model

You define your budget rules transparently, with flexible overrides:

- **Project Defaults:** Configured directly in the frontmatter of `.agent-harness/planner.md` (which templates into each `.worktree-task.md`):
  ```yaml
  max_task_budget: 2.00   # Max USD allowed for this task
  alert_threshold: 0.80   # Warn at 80% consumption
  ```
- **Runtime Overrides:** Set via environment variables for easy manual or automation overrides:
  ```bash
  export WTCRAFT_MAX_BUDGET=5.00
  ```

---

## 2. Real-time Event Hooks (Velocity, Cache & Models)

Instead of checking your API dashboard post-factum, `wtcraft` gives you active budget feedback during the lifecycle of each task:

### Phase A: Task Initiation (`wtcraft new`)
When starting a task, the assistant reads the project's recent token velocity and predicts costs:
- **Velocity Check:** *"Daily budget consumed: $0.42 / $5.00 limit."*
- **Model Recommendation:** *"This task touches only 2 small files. Consider running with Gemini 1.5 Flash to save ~$0.35 over Claude 3.5 Sonnet."*

### Phase B: Verification loops (`wtcraft verify` / `wtcraft check`)
Before/after running smoke tests or verification commands, the assistant parses the active worktree session logs:
- **Burn-Rate Alerts:** If a session's token consumption gradient is steep:
  > [!WARNING]
  > **High Token Burn-Rate Detected!**
  > At your current velocity ($0.62/min), you are projected to exhaust your remaining $0.40 budget in **38 seconds**. Consider committing current changes and restarting the session to compact history.
- **Cache Optimization Suggestions:** Monitors prompt cache hits to ensure you are maximizing discounts:
  > [!TIP]
  > **Cache Efficiency is Low (32%):**
  > You are paying full price for prompt context. To enable Claude's prompt caching, avoid making minor edits to files outside of your target scope to prevent context invalidation.

---

## 3. The `wtcraft budget` CLI Command

A single, lightweight command to see where your money went across all active session logs (parsing local session records with absolute local privacy):

```bash
wtcraft budget [--days 7] [--detail]
```

It outputs a highly readable ASCII table of token metrics, cache hit efficiency, estimated USD spend, and rule-based recommendations to optimize your developer setup.

---

## 4. Supported Agents & Log Parsers

`wtcraft` parses local CLI records to compile its reports:
1. **Claude Code CLI:** Parses JSONL logs in `~/.claude/projects/` matching the current workspace path.
2. **Gemini CLI:** Integrates with local Gemini API invocation metrics.
3. **Aider / Codex:** Parses standard chat history and cost logs where available.
