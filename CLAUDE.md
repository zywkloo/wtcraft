<!-- wtcraft:claude:start -->
## wtcraft routing
For complex or parallel tasks, read `.agent-harness/planner.md`.
For worktree finishing, read `.agent-harness/finisher.md`.

## repo structure (wtcraft dogfooding)
`templates/` is the source of truth for files `wtcraft init` copies to user repos.
The corresponding live files in this repo are wtcraft's own dogfooded versions:

  templates/.agent-harness/                    ↔  .agent-harness/
  templates/.claude/commands/                  ↔  .claude/commands/

When changing harness behavior: update both the template AND the live file.

## model knowledge policy
Never rely on your own training knowledge for model names or IDs — it is always outdated.
For model recommendations, read `.agent-harness/role-models.yml`.
If the user states a model name, that overrides everything else.

## release guardrails
- Version tags must use `v<semver>` format (example: `v0.3.8`).
- Version tags must be created from `main` only.
- Never create or move version tags from feature/worktree branches.
- `CHANGELOG.md` is the single source of release notes: add the version's section there before tagging. The publish workflow reads that section into the GitHub Release — do not hand-write release notes separately.
<!-- wtcraft:claude:end -->
