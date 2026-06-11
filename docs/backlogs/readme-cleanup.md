# README Cleanup Plan

> Status: deferred — implement after role-models.yml + codegen PR lands.

## Problem

The README has grown to ~250 lines and buries the Quick Start. A new user has to scroll past a large architecture diagram, implementation status callouts, role descriptions, and prior art references before they can run `wtcraft init`.

## What to Cut or Move

| Section | Current state | Action |
|---|---|---|
| ASCII art diagram (lines 49–83) | Duplicates the mermaid diagram | **Remove** — keep mermaid only |
| Role description bullets (lines 90–96) | Prose repeating what the diagram already shows | **Remove** — diagram is self-explanatory |
| "Implementation Status" callout (lines 85–88) | Repeats roadmap content | **Remove** — link to `docs/roadmap.md` instead |
| "Prior Art" table (lines 225–233) | Valuable but belongs in principles | **Move** to `docs/principles.md` |
| "Why" section (lines 98–106) | Good content but too early | **Move** below Quick Start |
| mermaid diagram + role bullets | Currently hand-authored | **Becomes codegen output** after role-models PR — add `<!-- wtcraft:models:start/end -->` markers |

## Target Structure

```
1. Tagline + badges
2. Install (one-liner, 3 options)
3. Quick Start (commands only)
4. The Layered Team (mermaid diagram — codegen-managed)
5. Commands table
6. Why (brief)
7. Links to docs/
```

## Target Length

~100 lines (down from ~250).

## Dependency

Wait for the role-models.yml + codegen PR to land first — that PR adds `<!-- wtcraft:models:start/end -->` markers to the README and makes the diagram codegen-managed. The cleanup PR then trims everything around it.
