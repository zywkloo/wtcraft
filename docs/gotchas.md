# wtcraft Gotchas & Claude Vibe (CV) Coding Survival Guide

Welcome to the real world of **Claude Vibe (CV) coding** and git-native multi-agent orchestration. While the concept of running isolated, parallel agent sandboxes in git worktrees is beautiful, practical engineering always introduces friction. 

Here are the **Top 5 Gotchas** you will inevitably encounter when moving from simple demos to production-level Vibe Coding, along with their pragmatic, battle-tested workarounds.

---

## 1. The "Zombie `node_modules`" Disk Bloat
### 🚨 The Symptom
You spin up 5 concurrent feature branches to parallelize your tasks. The Executor agent in each sandbox immediately runs `npm install` or `npm ci` to get the dependencies. Within minutes:
- You lose **3GB+ of disk space** to duplicate package folders.
- The sandboxes take **3–5 minutes** just to initialize, burning developer time and terminal attention.

### 💡 The Gotcha
Standard package managers (`npm`, `yarn` v1) copy package files physically. Running them inside separate git worktrees defeats the lightweight nature of git checkouts.

### 🛠️ Battle-Tested Fixes
* **Option A: Emplpy `pnpm` (Highly Recommended)**: `pnpm` uses a single global content-addressable store. When running `pnpm install` in a new worktree, it creates **hard links** to the global store instead of copying files. Setup time drops to under **5 seconds**, and disk overhead is **zero**.
* **Option B: Symlink the Root**: If you must use standard `npm`, symlink the parent worktree's `node_modules` during sandbox initialization:
  ```bash
  ln -s ../../node_modules ./node_modules
  ```

---

## 2. The "Nested Git Pointer" Agent Confusion
### 🚨 The Symptom
You invoke a terminal agent (like Claude Code) inside a new worktree sandbox. You ask it to make a change and commit. Instead:
- The agent gets confused, claiming: *"I cannot find a git repository here"* or *"This directory has no .git folder"*.
- Or worse, it runs `git init` inside the sandbox, creating a nested git repository that breaks your parent workspace tracking.

### 💡 The Gotcha
In a standard git repository, `.git` is a **directory**. In a `git worktree`, `.git` is a **plain text file** containing a pointer link back to the parent repository:
```text
gitdir: /path/to/main/repo/.git/worktrees/chore-my-feature
```
Naive terminal agents or standard CLI tools parsing only directories will fail to recognize the worktree as a git repository.

### 🛠️ Battle-Tested Fix
Ensure your `.agent-harness/executor.md` contains an explicit guidance block for the agent:
> *"You are operating inside a git-native worktree sandbox. The `.git` path here is a text pointer file, not a directory. All git operations (`git status`, `git add`, `git commit`) work normally via standard git commands. Do NOT run `git init`."*

---

## 3. The "Shallow Clone / Missing Tag" CD Catastrophe
### 🚨 The Symptom
You push a tag `vX.Y.Z` or run a manual deployment script from a GitHub Actions runner. The release step fails with an error:
`Error: No tag found to release` or `git describe failed: fatal: No names found, cannot describe anything.`

### 💡 The Gotcha
Most modern CI/CD systems and actions (like `actions/checkout@v4`) perform a **shallow clone** (`fetch-depth: 1`) by default to save bandwidth. Shallow clones do **not** fetch tags or deep history. When your deployment script runs `git describe` or `git tag -l` to resolve versions, git finds nothing.

### 🛠️ Battle-Tested Fix
Always configure your CI/CD checkouts to download the full repository history (`fetch-depth: 0`) when running CD release pipelines:
```yaml
- name: Checkout repository
  uses: actions/checkout@v4
  with:
    ref: main
    fetch-depth: 0 # Fetches all tags and commits
```

---

## 4. The "Untracked File Linter Blindspot"
### 🚨 The Symptom
The Executor agent writes a beautiful new utility class in `src/utils/helpers.ts`. It runs your tests, everything passes, and it declares the task complete. However, when the code is pushed and merged, production breaks because the helper file contained a syntax error or typescript warning.

### 💡 The Gotcha
Many modern linters (like ESLint, Prettier, or TypeScript configurations) or custom CI verifiers are optimized to **only check git-tracked files** to speed up execution. If the agent creates `src/utils/helpers.ts` but forgets to `git add` it, the linter **ignores** it during sandbox verification, creating a massive quality loophole.

### 🛠️ Battle-Tested Fix
* Ensure your task verification commands run globally, or force-add all untracked files to the index before checking:
  ```bash
  # Force-track all files (intent-to-add) so linters and checks see them
  git add -N .
  ```
* `wtcraft check` is designed to flag untracked files against the `Scope` contract to prevent this exact leak.

---

## 5. The Infinite Loop Token Burn ($50 Loop)
### 🚨 The Symptom
You go grab a cup of coffee while your autonomous agent runs in the background to solve a tricky bug. When you return:
- Your terminal is filled with 100 iterations of: `Failed to compile -> Fix -> Failed to compile -> Fix`.
- Your daily token API quota has been **exhausted**, and you just spent **$50** on repeated context-heavy compilation logs.

### 💡 The Gotcha
Autonomous loops lack natural cognitive pausing. When faced with a complex error, an agent will continuously attempt naive fixes, sending the entire codebase context back and forth with each compilation loop, inflating cost exponentially.

### 🛠️ Battle-Tested Fix
* **Hard Iteration Caps**: Never run terminal loops without an explicit limit (e.g. `claude --max-steps 10` or a hard retry limit inside your wrapper script).
* **The Orchestrator Watchdog**: This is the exact reason `wtcraft` is developing the **Quota Safety Switch** in Phase 5 to actively monitor aggregate session token cost and kill runaway loops before they drain your wallet.
