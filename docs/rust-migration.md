# Rust Migration Plan

> Status: under consideration — not yet scheduled.

## Motivation

The core wtcraft CLI is a bash script (~640 lines). It works, but has structural weaknesses that Rust would resolve:

- **Windows native support**: users currently need Git Bash. A compiled Rust binary runs natively on Windows with no shell dependency.
- **Fragile awk/sed parsing**: 5 core functions parse markdown/YAML with awk — any format variation can silently produce wrong output.
- **Testability**: the awk/sed logic has no unit tests and is hard to add them. Rust has built-in testing.
- **model_policy**: the fuzzy match + freshness rules planned for `role-models.yml` are a natural fit for typed Rust pure functions.

## Where Rust Helps vs. Doesn't

| Area | Rust advantage | Notes |
|---|---|---|
| Windows native support | ✅ | No Git Bash required — single `.exe` |
| awk/sed parsing | ✅ | `collect_section_items`, `extract_frontmatter` etc. have silent edge-case failures; Rust parsers are explicit |
| glob matching | ✅ | `file_matches_scope_item` has known edge cases; `glob` crate is a correct implementation |
| Testability | ✅ | bash awk/sed logic is nearly untestable; Rust has built-in unit tests |
| model_policy | ✅ | fuzzy match + freshness check are natural typed pure functions |
| Performance | ❌ | bash is fast enough; no measurable gain |
| git operations | ❌ | both shell out to `git` CLI — identical |
| Simple file copy | ❌ | `copy_if_missing` is trivial in bash; no benefit from porting |

## User-Facing CLI: No Change

The `wtcraft <command>` calling convention is **identical** before and after migration:

```bash
wtcraft init
wtcraft new feat/my-task
wtcraft status
wtcraft check <worktree>
wtcraft verify <worktree>
wtcraft patch / unpatch
wtcraft help [command]
```

The binary underneath changes; the interface does not. Existing scripts, CI configs, and agent harness docs require zero updates.

## Fragile Points (migration priority)

| Function | Line | Risk | Priority |
|---|---|---|---|
| `collect_section_items` | 414 | markdown format changes break parsing | high |
| `collect_verification_commands` | 431 | same | high |
| `remove_managed_block` | 245 | complex awk line-buffering logic | high |
| `extract_frontmatter` | 331 | YAML edge cases | medium |
| `sed` in `cmd_new` | 401 | simple substitution, low risk | low |

## Workload Estimate

| Module | What it covers | Estimate |
|---|---|---|
| `init / patch / unpatch` | file copy + marker management | 2–3 days |
| `status` | git worktree list + frontmatter parse | 1–2 days |
| `new` | git worktree add + task file seed | 1 day |
| `check` | section parse + glob matching (most complex) | 3–4 days |
| `verify` | subprocess + timing + reporting | 2–3 days |
| `model_policy` | fuzzy match + freshness pure functions | 1 day |
| Distribution / CI | cross-compilation + npm/pip/brew repackaging | 3–5 days |
| **Total** | | **~3 weeks** |

## Rust Dependencies

- `serde` + `serde_yaml` — YAML parsing
- `glob` — pattern matching
- `git2` or `std::process::Command` — git operations
- `regex` — markdown section parsing

## Distribution Changes

| Channel | Current | After migration |
|---|---|---|
| npm | ships `scripts/wtcraft` bash | downloads platform binary from GitHub Releases |
| pip | Python launcher → bash | Python launcher → platform binary |
| Homebrew | formula runs bash | formula installs pre-compiled binary |
| Source | `chmod +x scripts/wtcraft` | `cargo build --release` |

GitHub Releases would provide pre-compiled binaries for:
- macOS arm64 / x86_64
- Linux x86_64 / arm64
- Windows x86_64

## Recommended Approach: Incremental

Rather than a big-bang rewrite, migrate the highest-risk pieces first:

1. **Phase 1**: Rewrite `check` + `verify` in Rust — the most fragile and most tested commands. Bash calls the Rust binary as a subprocess.
2. **Phase 2**: Port `status` + `new` — simpler, lower risk.
3. **Phase 3**: Port `init / patch / unpatch` — file operations + marker management.
4. **Phase 4**: Remove bash entirely. Rust binary is the sole entrypoint.

This lets the existing bash script stay the authoritative implementation while Rust commands are proven incrementally.

## Non-goals

- Rewriting the agent harness docs (`.agent-harness/*.md`) — those stay markdown
- Replacing git itself
- Building a hosted control plane
