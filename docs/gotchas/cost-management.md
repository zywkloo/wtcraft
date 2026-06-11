# Cost Management & Token Governance Gotchas

## 1. The Infinite Loop Token Burn ($50 Loop)
### 🚨 The Symptom
You go grab a cup of coffee while your autonomous agent runs in the background to solve a tricky bug. When you return:
- Your terminal is filled with 100 iterations of: `Failed to compile -> Fix -> Failed to compile -> Fix`.
- Your daily token API quota has been **exhausted**, and you just spent **$50** on repeated context-heavy compilation logs.

### 💡 The Gotcha
Autonomous loops lack natural cognitive pausing. When faced with a complex error, an agent will continuously attempt naive fixes, sending the entire codebase context back and forth with each compilation loop, inflating cost exponentially.

### 🛠️ Battle-Tested Fix
* **Hard Iteration Caps**: Never run terminal loops without an explicit limit (e.g. `claude --max-steps 10` or a hard retry limit inside your wrapper script).
* **The Orchestrator Watchdog**: `wtcraft` advocates for strict task boundaries. If an agent hits its iteration limit without passing `wtcraft verify`, it should pause and request human or Planner intervention.
* **Financial Gating (Upcoming)**: As part of the Zero-Trust Governance layer, we are proposing budget contracts (`budget: $0.50` in `.worktree-task.md`) where `wtcraft check` or CI checks will aggressively kill or block processes that burn more tokens than their contractual allowance.
