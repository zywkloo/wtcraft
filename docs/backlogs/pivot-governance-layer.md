# Pivot Strategy: The Governance & Containment Layer

**Status:** Idea / Conceptual  
**Date:** 2026-06-10  

## The "Aha!" Moment
Currently, `wtcraft` positions itself as a "Cheap Token Orchestrator" (coordinating multiple agents to save money). However, orchestrating agents is a crowded space (AutoGPT, ChatDev, etc.). 

Our unique, hard-to-replicate advantage is **Git-native Worktree Containment**. AI agents (and human contributors) hallucinate, over-engineer, and accidentally break unrelated code. If we pivot to focus strictly on **Governance, Gating, and Violation Detection**, `wtcraft` becomes an indispensable "Containment Vessel" for *any* AI coding workflow.

## The New Value Proposition
*From:* "Run multiple cheap agents together."
*To:* **"Zero-trust containment and governance for AI-generated code."**

We provide the definitive safety harness for agentic coding. You let your AI write code; `wtcraft` ensures it strictly obeys the boundaries, scope, and verification rules before that code ever touches your main repository.

## Strategic Direction & Features

### 1. Ironclad Worktree Gating (The Containment Vessel)
- **Scope Lock-down:** The `.worktree-task.md` evolves into a strict `governance.yml` or strict contract.
- **Pre-commit / Pre-push Hooks:** Automatically inject local Git hooks so an agent *physically cannot* commit out-of-scope files.
- **Blast Radius Limits:** Define global off-limits (e.g., `db/migrations/` or `auth/` is strictly locked out for all AI agents).

### 2. Violation Detection & Auditing
- **Rich Violation Reports:** `wtcraft check` becomes `wtcraft audit`. Instead of just pass/fail, it outputs detailed JSON/Markdown reports: "Agent attempted to modify 2 files outside of scope: `api/user.ts` (Rejected)".
- **Security & Pattern Scanning:** Extend `check` to look for leaked secrets or banned anti-patterns in the worktree before merge.

### 3. Governance Visualization (Dashboarding)
- **Local TUI / CLI Dashboard:** A dynamic `wtcraft board` (terminal UI) showing all active worktrees across the repo.
- **Visual Status:** 
  - 🟢 `feat/auth` (Verified, In-Scope)
  - 🔴 `fix/typo` (Violation: Touched off-limits file)
  - 🟡 `chore/deps` (Pending Verification)
- **Web Export:** `wtcraft report --html` to generate a static HTML visualization of who is doing what and which boundaries were broken.

### 4. Zero-Config CI Enforcement (Auto-CI)
- **`wtcraft init-ci`**: Automatically generates `.github/workflows/wtcraft-gate.yml`.
- **PR Blocking**: When an AI agent (or junior dev) opens a PR, the CI parses the branch's `.worktree-task.md` and checks the PR diff against it. If the PR touches files outside the authorized scope, the CI automatically comments with the violation details and blocks the merge.

## What This Means We De-prioritize
To focus on Governance, we would step back from:
- Trying to build our own prompt-generation or LLM-calling scripts.
- Competing on "how smart our planner is".
Instead, we remain **LLM-Agnostic**. Users can use Aider, Cursor, Claude, or Devin. `wtcraft` just wraps their working directory in a zero-trust governance layer.

## Phase 1 Execution Backlog
1. [ ] Rename/alias `check` to `audit` and enrich the output format (support JSON output for machine readability).
2. [ ] Implement `wtcraft init-ci` to scaffold a GitHub Actions workflow that runs boundary checks on PR diffs.
3. [ ] Build `wtcraft board` (or enhance `wtcraft status`) into an interactive CLI table/TUI showing the containment status of all local worktrees.
4. [ ] Implement `wtcraft hook install` to enforce boundaries at the `git commit` level inside worktrees.
5. [ ] Update `README.md` to reflect the "Zero-trust AI Containment & Governance" narrative.
