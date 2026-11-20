# <Project name> — Project Tracker (<root, e.g. GH-12 or epic ABC-123>)

<!--
TEMPLATE — `/pw-open` copies this to `scratch/<root>-<short-name>/tracker.md` in the repo's main checkout.
Replace every <placeholder> and delete these guidance comments. A section exists only once something
occupies it; the commented shapes below are how to add one later. Keep the Shape line: `/pw-check` reads it.
-->

> **Living, gitignored tracker.** Lives ONLY in the main checkout: `<absolute path to this file>` — from a
> `.worktrees/<branch>` checkout, read and edit it by that path. Created <YYYY-MM-DD>. Never commit it.
> **Shape: project-workflow/v1.** Procedures: `/pw-land <project> <task-id>` · `/pw-land <project> close` ·
> `/pw-page` · `/pw-check [sweep]`.
> **Rules:** `<absolute path to the plugin's docs/project-workflow.md>` — read it before working from this tracker.
> **Tracker:** <tracker name from the repo config> · root <root key> · tickets close by: <owner | agent>.
>
> **Project shape:** <one or two lines — what this project builds, single- or cross-repo, the problem it attacks>.

## Status board

Tracker verified <YYYY-MM-DD> (<N>-key reconcile — <result>). **Critical path:** <D1 → D2 → …>.
Only started work has a row. Next work waits unnumbered in `decomposition.md` → Queue; starting it takes the next
D (or B) number in the Ledger there, moves its ticket under the root (or cuts one), and adds the row and bridge here.

<!--
Columns: Entry = the recipe up to /ce-plan (`/ce-brainstorm → /ce-plan`, or `/ce-plan`); Exit = at-Land skills
(`/ce-compound` or `—`). /ce-work runs between them for every row, so it has no column. Optional columns after
Deliverable: `Repo` (cross-repo projects), `Phase`. Tracker (the ticket's own status) and State are different
facts: keep both.
-->

| D | Ticket | Deliverable (plain English) | Entry | Exit | Tracker | State |
|---|--------|-----------------------------|-------|------|---------|-------|
| D1 | <KEY> | <outcome, not a step plan> | `/ce-plan` | `—` | In Progress | 🟡 — plan ready, awaiting `/ce-work` |

**Project-level tickets** (not deliverables): <the root · related tickets, one line each>.

<!-- LADDER INDEX — add with the first ladder. Shape:

## Ladders

| Ladder | Umbrella | State | File |
|--------|----------|-------|------|
| <NAME> | <KEY> | ⬜ 0/1 — <NAME>1 dispatchable; <n> queued | `ladders/<NAME>.md` |

One row per ladder; steps and their bridges live in the ladder file (from the plugin's templates/ladder.md).
-->

<!-- MESSAGES — add when a second thread is live; a single live thread writes to its own surface instead. Shape:

## Messages

- <YYYY-MM-DD> <FROM>→<TO>[,<TO>…]: <one-liner> [detail → <pointer>]
-->

## Next actions

Dispatch each item with the formula in the rules doc; its bridge below is the context.

1. **<D1 / CB3 / Queue handle> — <imperative next step>.**

## Open decisions

Decided entries → `archive/decisions.md` once amended into their owning surface.

- _(none open)_ · <or: **<question> — open (<who>, gates `<handle>`):** <frame> → `pages/<id>-<topic>.html`.>

---

## Per-deliverable detail

### D1 — <KEY> — <short name>

- **Dispatch bridge:** pre-work → `docs/plans/<file>` (this dir; the branch copy from `/ce-work` until merge) ·
  repo <repo> · base `<origin/dev>` · fence: <in scope / adjacent work out>.
- **Journal:** <short working notes; compressed to residue at 🟢 by `/pw-land`. Depth moves to `docs/`.>

<!-- SUB-DELIVERABLES — add inside the owning detail when the work splits. Shape:

| B | Sub-deliverable | State |
|---|-----------------|-------|
| B1 | <what it delivers> | 🟢 — #1234 |
| B2 | <what it delivers> | 🟡 — <in flight> |

Referenced elsewhere as D1:B2. The board cell carries only the roll-up (`🟡 1/2 — B2 in flight`).
-->

## Invariants (do not re-litigate)

- <a decision settled once that every thread honors>.
