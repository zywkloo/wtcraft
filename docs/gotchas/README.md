# wtcraft Gotchas & Coding Survival Guide

Welcome to the real world of git-native multi-agent orchestration and Zero-Trust Governance. While the concept of running isolated, parallel agent sandboxes in git worktrees is beautiful, practical engineering always introduces friction. 

Here are the battle-tested survival guides for common issues you will inevitably encounter:

* **[Worktree Sandboxing Gotchas](./worktree-sandboxing.md)**
  Issues with disk bloat, `node_modules` duplication, and Agents getting confused by `.git` pointer files.
* **[CI/CD & Verification Gotchas](./ci-cd-verification.md)**
  Issues with shallow clones breaking CD tags, and linters ignoring untracked files created by Agents.
* **[Cost Management & Token Governance](./cost-management.md)**
  Issues with runaway autonomous loops draining your API budget.
* **[LLM Anti-Patterns & Hallucination Triggers](./llm-anti-patterns.md)**
  Issues with LLM prompt design, including the "Pink Elephant" (Irony of Negation) problem and Sycophancy.
