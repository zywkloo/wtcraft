# Preset System + Codegen (role-models v2)

Status: in progress — PR #22 (`feat/role-models-v2-codegen`).

## What

`scripts/gen-presets.py` reads `templates/.agent-harness/role-models.yml` (STOT)
and generates:

1. **4 preset files** under `templates/.agent-harness/presets/` — all generated,
   including balanced (not a hand copy of STOT):
   - `preset-balanced.yml` — STOT ordering
   - `preset-anthropic.yml` — Claude CLI promoted to primary for all roles where available
   - `preset-openai.yml` — Codex CLI promoted
   - `preset-google.yml` — Gemini CLI promoted

2. **README.md mermaid diagram + role bullets** — between
   `<!-- wtcraft:models:start -->` / `<!-- wtcraft:models:end -->` markers.
   Same managed-block pattern as `wtcraft patch`.

Codegen runs manually before packaging: `python scripts/gen-presets.py`.
Future: wire into `pyproject.toml` build hook or Makefile.

## Key Design Decisions (with rationale)

### Format: keep YAML (not JSON/TOML)

JSON has no comments — fatal for a user-facing config 小白 users edit by hand.
TOML is less universal. YAML is human-editable, LLM-readable, and has
first-class support in all major languages.

### Schema: all values are single-line scalars

No YAML arrays or nested objects. Every field is `key: value` on one line.
`fallback` is a comma-separated string: `cli:Model Name, cli:Model Name`.

**Why**: bash/awk can extract any field with a simple key-match. The nested
object version (name/version/provider per entry) required a proper YAML parser
— which ruled out bash and made Rust or Python a *requirement*, not an option.
The scalar encoding makes bash viable now and Rust an upgrade later.

### Primary routing key: `cli`, not `model`

Most users run subscription CLIs (Claude Pro, ChatGPT Plus, Gemini), not API
keys. Subscriptions cannot be programmatically queried for quota and offer
limited model selection. Therefore:

- `cli` = the binary to invoke (claude / codex / gemini) — **the routing key**
- `model` = hint only, honored when API key or `--model` flag is supported;
  ignored for subscription users

### Preset files are full replacements, not overlays

User copies a preset over `role-models.yml`:
```bash
cp .agent-harness/presets/preset-anthropic.yml .agent-harness/role-models.yml
```
No merge/overlay needed. Simpler mental model for non-technical users.

### Freshness + fuzzy matching declared in config, not hardcoded

```yaml
matching:
  fuzzy: true              # normalize spaces, dashes, underscores, case
  freshness_tolerance: 0.2 # version gap threshold — user-configurable
```

The `0.2` magic number lives in the config so users can change it.
Matching rules are enforced by agents and (eventually) `wtcraft model-select`.

## Files Touched (PR #22 scope)

| File | Change |
|---|---|
| `templates/.agent-harness/role-models.yml` | New flat schema (STOT) |
| `.agent-harness/role-models.yml` | Live dogfooding copy |
| `templates/.agent-harness/presets/preset-*.yml` | Codegen output (4 files) |
| `scripts/gen-presets.py` | New codegen script |
| `README.md` | Add `<!-- wtcraft:models:start/end -->` markers |
| `pyproject.toml` | Add `presets/` to package-data |
| `scripts/wtcraft` cmd_init | Copy `presets/` directory |
| `templates/.agent-harness/executor.md` + live | Reference role-models.yml; document matching rules |

## Dependencies and Follow-ons

- `wtcraft model-select` (next PR) — turns this config into an executable
  command; see `../model-select.md`
- README cleanup — deferred until codegen markers are in; see
  `../readme-cleanup.md`
- Rust core extraction — `model-select` is the recommended first module to
  port (pure functions, zero IO); see [006-rust-core-extraction.md](006-rust-core-extraction.md)
