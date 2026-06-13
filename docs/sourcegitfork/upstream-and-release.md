# Upstream and release

## Upstream relationship

Intel gathered 2026-06-11:

- The fork owes upstream nothing. SourceGit is MIT and fork-and-diverge is a
  normal option.
- No prior issue or PR requests per-worktree metadata display. The closest
  discussions concern main-repository/worktree indication and linked branch
  indication.
- Maintainer `love-linger` is the dominant contributor, responds in Chinese,
  ships worktree clarity fixes quickly, and applies a strict filter on
  information density.
- External worktree feature PRs have often closed unmerged after discussion.

Therefore, any upstream proposal should be issue-first and framed as generic
"many worktrees are difficult to distinguish" metadata, not as an AI-agent
feature. A maintainer reimplementation of Layer 1 is also a good outcome
because it makes the fork's mount point upstream-owned.

Incidental bug fixes, localization fixes, and small UX contributions found
while working in the codebase can keep the rebase relationship healthy.

## Fork hygiene

- Keep `main` tracking upstream `main`.
- Do fork-specific work on a `governance` branch and release from it.
- Rebase onto upstream monthly.
- Favor new files plus minimal hooks in upstream-owned files.
- Keep the upstream MIT attribution intact.

## Signing and release

- **v0.1:** unsigned everywhere, matching upstream practice.
- **Later macOS:** Developer ID and notarization through the existing Apple
  Developer membership.
- **Windows:** remain unsigned initially. SignPath.io may be viable for OSS;
  paid OV certificates are not worthwhile at hobby scale.

Before distributing the fork broadly, rename the application identity and
app-data directory so it can coexist safely with upstream SourceGit.
