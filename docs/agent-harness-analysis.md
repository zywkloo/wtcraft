# Agent Harness & Multi-Agent Workflow Analysis

## Overview: Claude Teams & Claude Codex Bridge
Before diving into the full analysis, here is the requested clarification on the two specific terms:
- **Claude Teams**: Officially, this refers to Anthropic's organizational plan for Claude, enabling user management, billing, and shared context among a team of human users. In the context of agent workflows (e.g., "Claude Squad" or "Claude Code Agent Team"), it typically refers to community-driven or experimental setups where multiple instances of Claude Code are spun up in parallel to tackle distinct parts of a codebase simultaneously.
- **Claude Codex Bridge (CCB)**: This is an open-source, community-developed concept/project designed to bridge different AI agents and CLI tools. It acts as an intelligent Model Context Protocol (MCP) server or workspace manager that orchestrates task delegation between different coding agents (such as Claude Code and OpenAI's Codex CLI). It frequently utilizes multiplexers like `tmux` and Git worktrees to manage persistent, parallel CLI sessions, allowing agents to call one another as tools for tasks like peer review or architectural handoffs.

---

## Part 1: Product Categories & Solutions
### 1. Agent Harnesses & Orchestrators
- **Products**: AutoGen, LangGraph, CrewAI, PydanticAI
- **Target Users**: AI Application Developers, Enterprise Engineering Teams.
- **Architecture**: DAG-based routing, State Machines, Publisher/Subscriber event buses.
- **Strengths**: Highly flexible, native programming language integrations, strong community support.
- **Weaknesses**: Steep learning curve, often theoretical or overkill for simple tasks, lacking deep IDE/CLI integration out-of-the-box.

### 2. Worktree & Workspace Managers
- **Products**: Worktrunk, WorkMux, Claude Squad
- **Target Users**: Power developers, AI coders scaling their output.
- **Architecture**: CLI wrappers over `git worktree` and terminal multiplexers (`tmux`, `screen`) to orchestrate parallel agent sessions.
- **Strengths**: True parallel execution, zero-conflict Git branches, leverages existing robust terminal primitives.
- **Weaknesses**: Niche, relies heavily on terminal proficiency, hard to scale beyond a single machine without complex cloud orchestration.

---

## Parts 2, 3 & 4: The Landscape
- **Open Source Frameworks**: Tools like OpenHands, SWE-Agent, OpenDevin, and MetaGPT are pioneering the "agentic software engineer" space. They provide the core autonomous execution loop (read, write, test, iterate) but often struggle with parallelization.
- **Worktree-Specific Context**: Single-threaded agents are a massive bottleneck. Tools like Worktrunk and WorkMux solve this by placing each agent in a separate Git worktree. This allows multiple agents to work on the same repository simultaneously without file locking or Git conflict issues until merge time. "Harness Engineering" is the emerging discipline of building these boundaries.

---

## Parts 5 & 6: Enterprise & State Machines
- **Enterprise Workflow**: Atlassian Rovo, GitHub Copilot Workspace, Jira AI Agent. These aim to map the agent's code contributions directly to Project Management issues, abstracting away the terminal entirely.
- **State Machines**: Event-driven architectures (like LangGraph or AWS Step Functions for agents) are becoming the standard to ensure system reliability. They enforce "Human-in-the-Loop" (HITL) checkpoints, explicit task contracts, and reliable failure recovery, moving away from simple prompt-looping.

---

## Parts 7 & 8: Real-World & Academic
- **Real-World Deployments**: Deployments like Devin, Stripe Minions, and Google Jules highlight a shift in focus: the "harness" (the sandboxed environment, robust permission system, and execution state tracking) is more crucial than the underlying LLM's intelligence for production reliability.
- **Academic Research**: Currently focused on Dynamic Task Decomposition (TDAG) and advanced Agent Memory Architectures to prevent context degradation in long-running tasks.

---

## Part 9: Evaluating wtcraft
`wtcraft` stands out as a focused worktree/workspace orchestration tool. 

**Score (Out of 10):**
1. **Isolation**: 9/10 (If leveraging Git worktrees, isolation is native and robust).
2. **Context management**: 7/10 (Depends on how parent branch state is fed to the agent).
3. **Verification**: 6/10 (Needs tight CI/CD integration for automated testing).
4. **Human review**: 8/10 (Git PRs are the perfect native fit for asynchronous human review).
5. **State machine**: 5/10 (Likely relies heavily on Git's state rather than an internal programmatic state machine).
6. **Scheduling**: 4/10 (Needs external cron or orchestration daemon for true long-running autonomy).
7. **Multi-model support**: 8/10 (Agnostic to the specific CLI agent running inside the worktree).
8. **Worktree support**: 10/10 (Its core competency).
9. **GUI readiness**: 3/10 (Inherently a CLI-first or terminal-first paradigm).
10. **Commercial viability**: 7/10 (A strong niche for power users, but needs a UI wrapper for mainstream enterprise adoption).

**Strategic Analysis:**
- **Unique Advantages**: Leverages native Git primitives instead of building proprietary file syncing. Zero-friction parallelization without reinventing version control.
- **Missing Pieces**: A robust web/GUI dashboard, native HITL review queues, and long-running remote cloud execution.
- **Easiest MVP Path**: A CLI tool that spins up an AI agent in a new worktree for a specific GitHub issue and automatically creates a PR upon completion.
- **Strongest Moat**: Deep integration with local developer workflows (Git/Tmux) that abstract away the complexity of multi-agent execution while keeping data local.
- **Biggest Threats**: GitHub Copilot Workspace or IDEs like Cursor integrating native worktree management and background agents directly into their platforms.

---

## Part 10: Answers to Specific Questions

**Q1: Is wtcraft closer to CrewAI, AutoGen, LangGraph, Jira, GitHub Projects, Claude Team, Worktrunk, or a new category?**
It is closest to **Worktrunk** and **GitHub Copilot Workspace**. It sits directly at the intersection of Agent Execution Frameworks and Source Control Management. It is less about LLM reasoning routing (like LangGraph) and more about environment orchestration.

**Q2: What category name best describes wtcraft?**
**Agent Workspace Manager** or **Agent Harness**. It provides the necessary infrastructure and boundaries for agents to do their jobs without stepping on each other's toes.

**Q3: What is the smallest product users would pay for?**
A CLI tool that allows a user to execute `wtcraft solve PR-123`. The tool automatically creates a background worktree, runs an agent (like Claude Code or Aider) to solve the issue, and notifies the user via OS notification or Slack when the PR is ready for review—all without interrupting their current active development branch.

**Q4: What features should NOT be built?**
- Do not build another LLM wrapper or complex prompt routing framework (leave that to LiteLLM/LangChain).
- Do not build a custom version control system (rely strictly on Git).
- Do not build a general-purpose project management tool (integrate via API with Linear/Jira/GitHub Issues instead).

**Q5: If one solo developer had 12 months, what roadmap would maximize adoption?**
- **Months 1-3**: Core local CLI. Perfect the worktree creation + agent orchestration (e.g., Tmux integration) loop.
- **Months 4-6**: Integration Layer. Connect to GitHub Issues/Linear so the pipeline becomes: Issue -> Worktree -> Agent Execution -> PR.
- **Months 7-9**: Remote Execution Harness. Build Docker/Sandbox support to offload agent execution to the cloud, so users don't burn local compute.
- **Months 10-12**: Team Dashboard. A lightweight web UI or IDE extension for managing the "Swarm" of agents, viewing their statuses, and approving their PRs.
