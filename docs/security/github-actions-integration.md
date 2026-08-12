# GitHub Actions Integration for Trusted Change Authorization

Status: v0.5 setup guidance. The example workflow is not enabled in the
wtcraft repository because this repository does not yet operate a protected
`wtcraft-policy` branch.

## What the example does

[`trusted-change-authorization.yml`](../examples/github-actions/trusted-change-authorization.yml)
is a same-repository pull-request check. It checks out the pull request's
trusted base commit, fetches two Git objects without checking out the PR code,
then runs the Git adapter:

```text
trusted base checkout
  + protected wtcraft-policy ref
  + fetched PR head object
              ↓
      policy_git_adapter.py
              ↓
policy commit + digest + changeset verdict
```

It deliberately does not execute the envelope's verification commands. Running
untrusted PR code in a privileged event requires a separate, least-privilege
design and is not solved by copying this workflow. The evidence still names the
reviewed plan with `"status": "not_executed"`, so a passing authorization is
never mistaken for a passing verification.

Two details in the example are load-bearing and must survive any edit:

- `fetch-depth: 0`. The adapter needs the merge base between the base tip and
  the PR head. A shallow checkout puts the fork point behind the graft
  boundary, and every PR whose base branch has moved on then fails with
  `merge_base_unavailable`.
- the evidence step captures the adapter's exit code instead of letting the
  shell abort on it, then prints and uploads the JSON. A denial exits non-zero,
  and aborting early would discard the evidence in the one case a reviewer
  actually needs to read it.

## Required repository setup

Before making the check required, an administrator must configure all of these:

1. Create `wtcraft-policy` and protect it from direct executor writes.
2. Require review for policy changes; use CODEOWNERS or an equivalent protected
   reviewer path for `.wtcraft/policies/**`.
3. Protect `.github/workflows/wtcraft-trusted-change.yml` and the wtcraft
   adapter implementation from ordinary task changes.
4. Copy the example workflow into the default branch and confirm it runs from
   the trusted base revision.
5. Open an intentionally unauthorized same-repository PR and verify that the
   job fails; then open an authorized PR and inspect its evidence JSON. Include
   a PR that renames a file out of an off-limits path, and one opened before
   the base branch advanced, so both fail-closed paths are exercised.
6. Only then make the exact job name `wtcraft / trusted-change-authorization`
   a required status check/ruleset requirement.

The check is an authorization gate only. Existing ordinary CI still owns test,
lint, and build results. Do not say that an authorization pass proves runtime
safety or that it replaces code review.

## Event and permission boundary

The example uses `pull_request_target` so the workflow definition and checkout
come from the target repository context. GitHub cautions that this event is
security-sensitive; a privileged job must not check out or execute untrusted
pull-request code. The job uses read-only `contents` permission and rejects
fork pull requests in v0.5. See GitHub's documentation on
[pull_request_target](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request_target).

Do not add any of the following to this job:

- `actions/checkout` at `github.event.pull_request.head.sha`;
- package installation, test execution, build steps, or scripts from the PR;
- repository, cloud, package-registry, or deployment secrets;
- restore/save caches that untrusted code could influence;
- write permissions, comments, labels, or automated merges.

If the repository uses a merge queue, it needs an additional `merge_group`
workflow path. GitHub notes that required checks otherwise do not run for merge
queue entries. Do not mark this v0.5 example required for a merge queue until
that path is designed and tested.
