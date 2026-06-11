# Worktree Sandboxing Gotchas

## 1. The "Zombie `node_modules`" Disk Bloat
### 🚨 The Symptom
You spin up 5 concurrent feature branches to parallelize your tasks. The Executor agent in each sandbox immediately runs `npm install` or `npm ci` to get the dependencies. Within minutes:
- You lose **3GB+ of disk space** to duplicate package folders.
- The sandboxes take **3–5 minutes** just to initialize, burning developer time and terminal attention.

### 💡 The Gotcha
Standard package managers (`npm`, `yarn` v1) copy package files physically. Running them inside separate git worktrees defeats the lightweight nature of git checkouts.

### 🛠️ Battle-Tested Fixes
* **Option A: Employ `pnpm` (Highly Recommended)**: `pnpm` uses a single global content-addressable store. When running `pnpm install` in a new worktree, it creates **hard links** to the global store instead of copying files. Setup time drops to under **5 seconds**, and disk overhead is **zero**.
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
