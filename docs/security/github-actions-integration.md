# GitHub Actions Integration for Trusted Change Authorization

Status: v0.5 setup guidance. The example workflow is not enabled in the
wtcraft repository because this repository does not yet operate a protected
`wtcraft-policy` branch.

## Installing it

```bash
wtcraft init-ci
```

This writes `.github/workflows/wtcraft-trusted-change.yml` plus the evaluator
it runs, at `.wtcraft/policy_git_adapter.py` and `.wtcraft/policy_evaluator.py`.

The evaluator is vendored into the repository rather than installed at check
time. The job is privileged and runs from the trusted base checkout, so adding
an install step would both widen it and drop the review requirement this
document places on the adapter implementation. The tradeoff is that a vendored
copy does not receive wtcraft's fixes: `init-ci` reports a vendored file that
differs from the installed wtcraft version, and `--force` refreshes it. Treat
that report as a security notice, not noise — the rename-bypass fix landed in a
released version, and a repository pinned to an older copy stays exploitable.

Existing files are never overwritten without `--force`.

The reference copy under
[`docs/examples/github-actions/`](../examples/github-actions/trusted-change-authorization.yml)
runs `scripts/policy_git_adapter.py` instead, because in this repository the
adapter is source, not a vendored artifact.

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

It deliberately does not execute the envelope's verification commands.
[ADR-011](../adr/011-verification-execution-least-privilege.md) explains why
sandboxing alone would not fix this: the adversary controls the task branch, so
it controls what those commands do, and a command the adversary wrote can
report whatever it likes. Execution becomes evidence only once the reviewed
policy also pins the plan's inputs. The evidence still names the
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
4. Run `wtcraft init-ci`, commit the result to the default branch, and confirm
   it runs from the trusted base revision. Pin `actions/checkout` and
   `actions/upload-artifact` by commit SHA before making the check required.
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
