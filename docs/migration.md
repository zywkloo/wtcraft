# Migration Notes

## 0.2.x → 0.3.x

### Glob patterns in `check` Scope / Off-limits

`wtcraft check` now supports glob patterns in `## Scope` and `## Off-limits`.

**Previous behaviour:** only exact file paths and directory prefixes matched.

**New behaviour:**

| Pattern | Matches |
|---|---|
| `src/index.ts` | exact file (unchanged) |
| `src/components` | anything under that directory (unchanged) |
| `*.md` | any `.md` file at any depth |
| `src/*.ts` | any `.ts` under `src/` at any depth |
| `src/**/*.ts` | same — `**` and `*` are equivalent in bash pattern matching |

**No migration required.** Existing task files without `*` in their patterns
continue to work identically — the exact/prefix path is checked first.

---

### Verify output format

`wtcraft verify` now emits:
- A separator line before and after each command's output
- Per-command timing and exit code on the result line
- A structured summary table after all commands finish

The **exit codes are unchanged**: `0` = all passed, `3` = one or more failed.

CI pipelines that parse `verify` stdout line-by-line may need to update their
patterns. The old `PASSED: <cmd>` / `FAILED (<code>): <cmd>` lines are replaced
by `PASSED (<elapsed>s)` / `FAILED (exit <code>, <elapsed>s)` immediately after
each command block, and the summary table at the end.

---

### Per-command help

`wtcraft help <command>` is now available for each subcommand:

```
wtcraft help init
wtcraft help check
wtcraft help verify
wtcraft help new
wtcraft help status
```

---

### npm packaging

wtcraft 0.3.0 can be installed globally via npm:

```sh
npm install -g wtcraft
```

The `scripts/wtcraft` shell script is the only runtime artefact — no Node.js
execution is involved. npm is used for distribution only.

---

## 0.1.x → 0.2.x

### New commands

`wtcraft new` and `wtcraft verify` were added in 0.2.0.
No existing commands changed behaviour.

### Template updates

If you ran `wtcraft init` in 0.1.x, the new role docs (`executor.md`,
`finisher.md`) may be missing. Run `wtcraft init` again — existing files are
never overwritten, so only missing files are added.
