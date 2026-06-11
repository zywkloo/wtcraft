# CI/CD & Verification Gotchas

## 1. The "Shallow Clone / Missing Tag" CD Catastrophe
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

## 2. The "Untracked File Linter Blindspot"
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
