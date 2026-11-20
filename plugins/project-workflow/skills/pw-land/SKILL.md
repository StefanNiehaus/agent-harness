---
name: pw-land
description: Use when a deliverable, sub-deliverable or ladder step of a project has merged and must be landed, or when a whole project is done and must be closed — phrases like "/pw-land", "land D3", "land CB3", "wrap up D2:B3 now it merged", "close the <name> project", or "archive this project". `/pw-land <project> <task-id>` runs the Land sequence in hot context (compound, row flip, landed-doc cleanup, the ticket walk that closes only when the repo's `done` setting allows it, worktree cleanup last). `/pw-land <project> close` closes the project. It confirms no session is live, proposes ticket-or-drop for every piece of open work, writes nothing to the ticket tracker until the owner approves, then stamps the tracker file CLOSED and moves the folder to the project archive. Works on old-shape folders too, so they are closed rather than migrated.
---

# /pw-land — land a task, or close a project

Two explicit modes; the skill never infers which:

- `/pw-land <project> <task-id>` — **land** a deliverable (`D3`), sub-deliverable (`D3:B7`) or ladder step (`CB3`).
- `/pw-land <project> close` — **close** the whole project. This is the destructive path.

No mode word or task id → ask which.

## Start (every run)

1. **Find the plugin.** Resolve the real path of the folder that holds this `SKILL.md`, following symlinks (`cd -P "<skill folder>" && pwd -P`). The plugin root is two levels above that real path. Resolve first: shortening `..` against a symlinked path lands in the wrong place.
2. **Read the rules** at `../../docs/project-workflow.md` and this skill's `learnings.md`.
3. **Resolve the project** as `/pw-check` does: `main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')`, then `scratch/*/tracker.md` under the repos root matched against the argument. Several or none → list and ask.
4. **Read the repo config** from that main checkout: `.project-workflow.yml`, with any key in `.project-workflow.local.yml` applied over it. Neither file there, or no `tracker` key between them → stop with the opt-in message from the rules doc; write nothing. Note `done` (`owner` when unset) and `archive_root`.
5. **Load the op sheet** `../../trackers/<tracker>.md` for the config's `tracker`. No such sheet → stop, naming the missing file and `../../docs/adding-a-tracker.md`. Ops below are written as `op-name`; perform each exactly as the sheet says.

**Edits are targeted string replacements**, never whole-file rewrites. A ticket op that fails with an access error → stop and report; credentials can change.

## Land mode

Run by the working agent in hot context, right after the work merges.

1. **Find the task.** Its board row (`D3`), its `Bn` row in the deliverable's detail (`D3:B7`), or its step row in `ladders/<NAME>.md` (`CB3`); its bridge; its ticket (a ladder step has none — its PR cites the umbrella); its PR, branch and worktree.
2. **Check the PR.** MERGED → continue. Still open → stop: land runs after merge. Closed unmerged → repoint the bridge at the project-dir copies of its pre-work docs (they never left), set the row's clause, and stop.
3. **Compound first.** If the recipe's Exit carries `/ce-compound` and its learning is not on the base yet, run `/ce-compound` now, in this context. The PR merged, so commit its output on a fresh branch from the base and open a docs-only PR — ask the user before pushing.
4. **Flip the row** 🟢 with a short clause (`— #2365 (4.3.64)`); update the roll-up on the board row (a `Bn`) or the Ladders row (a step). Compress the task's journal to residue: follow-ups, lessons, carry-ins; follow-ups that are new work become Queue lines in `decomposition.md` (or the ladder's queue). Add the PR to the task's Ledger note.
5. **Delete landed doc copies.** For each pre-work doc the bridge pointed at in the project's `docs/`, confirm the copy is on the base (`git cat-file -e origin/<base>:<repo path>`), then delete the project-dir copy and repoint the bridge at the repo path.
6. **Walk the ticket** for the task. A sub-deliverable without its own ticket walks nothing; the parent deliverable's ticket walks only when its last `Bn` lands.
   - `done: owner` (the default): `advance-status` to 🟢, then `comment` with the PR link and "ready to close". **The ticket stays open; closing it is the owner's move, never yours.** Report "ready to close".
   - `done: agent`: `close` the ticket, unless the merged PR already closed it.
7. **Clean up the worktree last** — never before step 3's commit. The branch counts as absorbed when its PR is MERGED and its own files match the merge commit (`git diff <merge-commit> <branch> -- <its files>` is empty; a diff against today's base or `git cherry` misleads after squash merges and stacks). Then `git worktree remove <path>` and `git branch -D <branch>`. Uncommitted changes in the worktree → stop and ask.
8. **Report**: row flipped, ticket position, docs deleted, worktree removed, anything left for the owner.

Land touches only the task's own surfaces: its rows, detail or ladder file, its Ledger note, Queue lines it adds, and its own worktree.

**PR bodies before the merge.** Whoever opens a task's PR references its ticket in the form the sheet's `key-format` gives: the reference-only form under `done: owner`, the closing form only under `done: agent`.

## Close mode

Closing archives the folder and turns every surviving piece of work into a standalone ticket or an explicit drop. It works on any shape, including an old-shape folder with `tmp/`, a pre-numbered decomposition and no Ledger.

```
live-session gate → destination check → collect open work → proposal table → owner approval
  → ticket writes (key recorded on each item as written) → CLOSED stamp → destination re-check → move → report
```

### 1. Live-session gate

The plugin keeps no session registry, so the owner's confirmation is the gate. Collect the ticket keys named anywhere in the folder, and every repo it names: the board's `Repo` column, bridge `repo <name>` fields, and the repo holding the folder. Resolve each named repo as a sibling under the repos root (`<repos-root>/<name>`, where `<repos-root>` is the parent of the main checkout). Then, for each of those repos, show:

- worktrees (`git -C <repo> worktree list`) whose branch names one of those keys and that hold uncommitted changes or a commit from the last 24 hours. Match keys case-insensitively: branches usually carry the key in lower case;
- open PRs for those keys (`gh pr list -R <owner/repo> --state open --search <KEY>`, or run it from inside that repo).

List the repos checked, so the owner knows what an empty result covers; a named repo not found under the repos root is listed as not checked. Ask the owner to confirm that no session is working on this project. Not confirmed → **stop; nothing is written**.

### 2. Destination check

Destination: `<archive_root>/<repo-name>/<project-dir>/`, where `<archive_root>` is the config value, or `<repos-root>/project-archive` when unset, and `<repo-name>` is the main checkout's basename. It exists → **stop before the table**: report the collision; no ticket write, no stamp.

### 3. Collect open work

Every item that is neither done nor already disposed of, each with its source (`file:line`) and any ticket key on its line:

- `decomposition.md` Queue lines (all groups);
- tracker board rows and `Bn` rows not 🟢, ❌ or ⚪, and "not yet numbered" lines inside detail sections;
- each ladder as one item under its umbrella ticket, covering its steps not 🟢, ❌ or ⚪ and its queue lines (each a source line; key-less steps are not separate items);
- each non-root key on the tracker's Project-level tickets line (the root itself is never collected);
- `docs/future-*.md` notes (one item each);
- old shape only: unstarted numbered deliverables in the decomposition, and items under deferred-work headings such as Parked, Future, Backlog, Sub-deliverable outline.

Then merge items that name the same deliverable, sub-deliverable or step ID (`D3`, `D3:B2`, `CB4`) or the same ticket key — an old-shape folder can list one deliverable as a board row and a numbered decomposition entry — into one row whose Source lists every source line. A key carries exactly one proposal.

Read every existing key's status with one `read-ticket` call, following its pagination. A key that maps to 🟢 closed or ❌ in the sheet's `status-map` is not open work — list it under "already closed" and skip it. A line (for a whole-file item, the file's last line) carrying a recorded result from an earlier interrupted close (` → ticket <KEY>`, ` → cancelled <KEY>`, ` → dropped`) keeps that result: show it, never redo it.

### 4. Proposal table

```
| # | Item (plain English) | Source | Ticket | Proposal | Type | Reason |
|---|----------------------|--------|--------|----------|------|--------|
| 1 | Feed keeps the raw packet field | decomposition.md:62 | <KEY> | ticket | bug | real data loss, ~39% of packets |
| 2 | Rename the old identifiers | decomposition.md:48 | — | drop | — | owner deferred; little value alone |
```

- **Proposal** is `ticket` or `drop`; every drop carries a reason. Default to `ticket` for outcomes the owner still asked for, `drop` for work the decomposition already marks deferred without a use.
- **Ticket** with an existing key means keep that ticket and make it stand alone; with no key, create one. **Drop** with an existing key means cancel it as won't do. No duplicate ticket is ever created.
- **A ladder** is one row on its umbrella: `ticket` keeps the umbrella standalone with its open steps and queue lines written into a comment on it; `drop` cancels it as won't do. Never a new ticket per key-less step, unless the owner edits the table to split one out as its own row.
- **Type**: `task` by default, `bug` for a defect.
- New tickets are created where the op sheet's `cut` puts them for this repo's config. A folder with no root still uses the configured tracker.

Ask the owner to approve, edit, or decline. Edits → re-render the table and ask again. Decline → **stop; nothing is written**.

### 5. Ticket writes (after approval only)

For each approved item, in table order, and **immediately after each write append its result to the item's own line** in the folder, so a rerun reuses it. A merged row appends it to every one of its source lines, so a rerun cannot pick up another copy. A whole-file item (a `docs/future-*.md` note) records it as that file's last line, and on its pointer line in the tracker file or decomposition when one exists.

- new ticket: `cut` with no parent (title = the plain-English item; description = the item's line and its bridge or note text, with folder paths rewritten to their archive paths under the destination) → append ` → ticket <KEY> (closed <date>)`;
- kept ticket: `reparent` to `none` (a ladder umbrella also gets a `comment` listing its open steps and queue lines) → append ` → ticket <KEY> (closed <date>)`;
- cancelled ticket: `cancel` with the row's reason, then `reparent` to `none` → append ` → cancelled <KEY> (closed <date>)`;
- drop without a ticket → append ` → dropped (closed <date>): <reason>`.

A failure → stop, report what was written; the recorded results make a rerun safe. The root itself: under `done: owner` it is left alone and reported as ready for the owner to close; under `done: agent`, `close` it last.

### 6. Stamp, re-check, move

1. Insert under the tracker file's title, once: `> **CLOSED <YYYY-MM-DD> — record of record: <tracker> <ROOT>; cold reference only**` (rootless: `CLOSED <YYYY-MM-DD> — no root ticket; cold reference only`).
2. Re-check the destination. It exists now → **stop**, report the collision; a rerun after it is resolved reuses every recorded result.
3. `mkdir -p <archive_root>/<repo-name>/` and `mv` the whole project directory there — `pages/`, `proof/`, `tmp/` and `archive/` included.

### 7. Report

Tickets created, kept and cancelled (keys), items dropped, the archive path, the root's position (ready for the owner to close, or closed), and worktrees or branches left to clean up (flag only).

## Hard constraints

- **Close writes nothing** — no ticket op, no file edit, no move — before the owner confirms no live session **and** approves the table.
- Never create a second ticket for an item that has one.
- **Never `close` a ticket under `done: owner`**, in either mode. An obsolete ticket is always `cancel`led as won't do, never closed as done, under either setting.
- Never delete a worktree or branch in close mode; land mode deletes only the task's own, after the absorbed check.
- Never touch another archive folder, memory, or committed repo files (except a compound docs PR the user approved).

## Learnings

When a land or close misses open work, writes in the wrong order, or trips on a folder shape, append one dated line to this skill's `learnings.md` in the real skill folder (`### YYYY-MM-DD` then `- Observation. Source: <path / ticket>.`). Only when the class recurs or the user flags a miss. A lesson about one tracker's behavior goes in that tracker's op sheet instead.
