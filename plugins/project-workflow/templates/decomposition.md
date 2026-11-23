# <Root> — <Project name> — Decomposition (scope of record)

<!--
TEMPLATE — `/pw-open` copies this to `scratch/<root>-<short-name>/decomposition.md`. Replace every <placeholder>
and delete these guidance comments. The tracker routes; this file defines what the project will and won't do.
-->

> The tracker routes; this file defines. Requirements of record: <`docs/plans/<file>` cited by R-ID, or "none
> yet">. Snapshots of earlier cuts → `archive/`.

## End state

<two to four sentences: what is true when this project closes>.

## Working rules (owner, <YYYY-MM-DD>)

- **Number at start.** Work waits in the Queue as a named handle with no number. Starting it takes the next free D
  number (or its deliverable's next B number), adds a Ledger row, moves its ticket under the root (or cuts one), and
  only then gets a board row and a bridge in the tracker. Reorder, edit or drop Queue lines freely; a dropped line
  moves to Dropped with one reason.
- <any project-wide rule the owner sets, e.g. "proof by replay only">.

## Ledger (append-only; a number is assigned when the work starts)

| # | Handle | Started | Queue pos. at start | Note |
|---|---|---|---|---|

## Queue (proposed order; no numbers)

Docs named here live in this project's `docs/` or `briefs/` unless an absolute path is given.

**Inside D<n> (next B numbers):**
- `<handle>` — <outcome in one or two lines> · <ticket, if one exists> · <pointers> · fence: <what stays out>.

**Deliverables:**
- `<handle>` — <outcome> · <ticket> · <pointers> · fence: <what stays out>.

<!-- A ladder's small fixes queue in its own file; point at it here: **<NAME> ladder** → `ladders/<NAME>.md`. -->

## Not in this project

- **`future-` notes (revisit later):** <`docs/future-<date>-<topic>.md`, one line each>.
- **Related tickets, left as they are:** <keys>.

## Dropped

| Item | Reason |
|---|---|
