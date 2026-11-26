# Stoep sync — Project Tracker (GH-12)

<!--
TEMPLATE — guidance left in place on purpose: | D | not | a | row |
-->

> **Living, gitignored tracker.** Lives ONLY in the main checkout. Created 2026-11-01. Never commit it.
> **Shape: project-workflow/v1.** Procedures: `/pw-land <project> <task-id>` · `/pw-land <project> close` ·
> `/pw-brief` · `/pw-status [sweep]`.
> **Rules:** `/opt/example/project-workflow.md` — read it before working from this tracker.
> **Tracker:** example · root GH-12 · tickets close by: owner.
>
> **Project shape:** an invented sync feature for a fixture; hosts live at sync.example.com.

## Status board

Tracker verified 2026-11-22 (6-key reconcile — clean). **Critical path:** D1 → D3.
Only started work has a row.

<!--
Columns: Entry = the recipe up to /ce-plan. | D9 | <KEY> | guidance | `/ce-plan` | `—` | x | 🟡 — `/ce-work` |
-->

| D | Ticket | Deliverable (plain English) | Entry | Exit | Tracker | State |
|---|--------|-----------------------------|-------|------|---------|-------|
| D1 | GH-13 | Sync engine pulls remote changes into the local store | `/ce-brainstorm → /ce-plan` | `/ce-compound` | In Progress | 🟡 1/3 — B2 in flight |
| D2 | GH-14 | Push over a second transport | `/ce-plan` | `—` | Cancelled | ❌ — superseded by D3 |
| D3 | GH-15 | Offline queue survives restart | `/ce-plan` | `—` | In Progress | 🟡 — plan ready, awaiting `/ce-work` |
| D4 | GH-16 | Settings screen | `/ce-plan` | `—` | Done | 🟢 — #41 |
| D5 | GH-17 | Conflict banner in the app | `/ce-plan` | `—` | To Do | 🔴 — gated on D1, then `/ce-work` |
| D6 | GH-18 | Export every synced record to a portable archive that other tools can import without any loss of history or ordering | `/ce-plan` | `—` | In Review | 🟡 — fix review with `/ce-code-review`, then `/ce-commit` |

**Project-level tickets** (not deliverables): GH-12 — root.

## Next actions

Dispatch each item with the formula in the rules doc; its bridge below is the context.

1. **D3 — run the plan.**
2. **D1:B3 — start once B2 merges.**

## Open decisions

Decided entries → `archive/decisions.md` once amended into their owning surface.

- **Merge strategy for D1 — open (owner, gates `D1`):** last-write-wins or field merge → `briefs/d1-merge-strategy.md`.
- **Archive format for D6 — open (owner, gates `D6`):** zip or tar → `briefs/d6-archive-format.html`.
- ~~**Retry budget — decided:** three tries → `briefs/d1-retry.md`.~~

---

## Per-deliverable detail

### D1 — GH-13 — sync-engine

- **Dispatch bridge:** pre-work → `docs/plans/x.md` · repo example · base `origin/main`.
- **Journal:** —

| B | Sub-deliverable | State |
|---|-----------------|-------|
| B1 | Pull loop on a timer | ⚪ — folded into B2 |
| B2 | Local edits rebase over pulled ops | 🟡 — PR open |
| B3 | Conflict log | ⬜ — waits on B2 |

### D3 — GH-15 — offline-queue

- **Dispatch bridge:** pre-work → `docs/plans/y.md`.

## Invariants (do not re-litigate)

- Sync never deletes local data.
