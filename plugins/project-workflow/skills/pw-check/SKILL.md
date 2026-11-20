---
name: pw-check
description: Use when the user wants the state of a project (an effort tracked by a living `scratch/<root>-<slug>/tracker.md`) — phrases like "/pw-check", "check the <name> project", "where's the <name> project", "status of the <name> project", or "sweep the <name> project". Reads the project's tracker file FIRST, reconciles it against the live tickets in the repo's configured ticket tracker and the open PRs/branches/worktrees, then renders a plain-English deliverable table (each row says what it delivers, not just "D4"), the ladders, the Queue head, the critical path and next actions. Reads only the project-workflow/v1 shape; an old-shape tracker gets no board and a pointer to `/pw-land <project> close`. Default depth is a READ-ONLY snapshot; "sweep" adds tracker-file, ladder, archive and ticket maintenance and may write. Names a project by name, root key or tracker path; asks when ambiguous.
---

# /pw-check — project snapshot from the living tracker

Repeat-use skill. Produces a glanceable, plain-English status of a **project** — an effort split into deliverables and tracked by a living `scratch/<root>-<slug>/tracker.md`. The tracker file is the engine: read it first, then reconcile it against the ticket tracker (status of record) and reality (open PRs, branches, worktrees) so the snapshot is true even if the file drifted.

The headline output is a **deliverable table where every row says what it delivers in plain English** — never just `D4`.

## Start (every run)

1. **Find the plugin.** Resolve the real path of the folder that holds this `SKILL.md`, following symlinks (`cd -P "<skill folder>" && pwd -P`). The plugin root is two levels above that real path. Resolve first: shortening `..` against a symlinked path lands in the wrong place.
2. **Read the rules** at `../../docs/project-workflow.md` and this skill's `learnings.md`.
3. **Resolve the project** (below), then **read the repo config** from the main checkout that holds it: `.project-workflow.yml`, with any key in `.project-workflow.local.yml` applied over it. No `.project-workflow.yml` → stop with the opt-in message from the rules doc; render nothing.
4. **Load the op sheet** `../../trackers/<tracker>.md` for the config's `tracker`. No such sheet → stop, naming the missing file and `../../docs/adding-a-tracker.md`. Ops below are written as `op-name`; perform each exactly as the sheet says.

## Two depths (default is status)

- **`status`** (DEFAULT) — read-only snapshot. Read the tracker file, reconcile tickets + PRs/branches/worktrees, render. **No writes anywhere.**
- **`sweep`** — everything `status` does, **plus** maintenance that may write: fix tracker-file drift with targeted edits, archive what the rules send to `archive/`, advance plainly-stale tickets, and flag worktree cleanup. Trigger only on explicit "sweep" wording.

"check / where's / status of" → `status`. "sweep" → `sweep`. When unclear, default to `status` and say so.

## Resolving the project

Tracker files live in the **main checkout** of a repo at `scratch/<root>-<slug>/tracker.md` — gitignored, never in a worktree. Resolve the main checkout first:

```bash
main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
repos_root=$(dirname "$main")   # sibling repos usually sit under one root
find "$repos_root" -maxdepth 4 -path '*/scratch/*/tracker.md' -not -path '*/.worktrees/*' 2>/dev/null
```

Outside a git repo, ask which repo holds the project. Match the argument (a name, a root key, or a path) against the dir names and, if needed, each tracker's title line. Exactly one match → use it. Several or none → list them (dir + first heading) and ask; never guess. The repo config is read from the main checkout that holds the matched project.

## Shape check (before anything else)

Read the tracker file. A new-shape tracker carries the line `Shape: project-workflow/v1` in its header. **Without it, stop:** render no board, run no reconcile, write nothing (even in `sweep`), and answer:

> ⚠️ `<tracker path>` is an old-shape tracker (no `Shape: project-workflow/v1` line). Old trackers are not migrated. Next step: `/pw-land <project> close` — it proposes ticket-or-drop for the open work, waits for your approval, then archives the folder.

## Flow (status, new shape)

1. **Read the project surfaces.** From `tracker.md`: the header's `Rules:` path, board rows (State chip, optional `n/m` roll-up, clause), the Ladders table, Messages (unread count, oldest date, dead-letter candidates), per-deliverable detail (bridges and `Bn` tables — the source of each row's plain-English outcome), project-level tickets, critical path, next actions, open decisions. From `decomposition.md`: the Ledger's last row and the Queue (count of unnumbered handles, first two in order). Each listed `ladders/<NAME>.md`: its step table and queue length. `ls` of `docs/`, `pages/` and `proof/` (names, not content).

2. **Reconcile tickets.** Collect every key the tracker file, decomposition and ladders name (deliverables, project-level tickets, umbrellas, the root) and read them all with `read-ticket`, following its pagination to the end. Then `list-children` of the root and diff the result against the named keys: a ticket cut at dispatch can be missing from the board. Map each ticket's state to a chip with the sheet's `status-map`. A ticket that maps to 🟢 because it is *landed and waiting for its owner* agrees with a 🟢 row and is not drift. 🔴 has no ticket mapping (render its gate); ⚪ reconciles nothing (follow its pointer). Note every real drift.

3. **Reconcile reality.** For in-flight rows read the PRs the tracker file names (or `gh pr list --search <ticket key>`): `state,mergeable,mergeStateStatus,reviewDecision`. `git worktree list` and branches for cleanup candidates. `ls -t` the project's `docs/plans/` and match any plan newer than the board's verified date against ⬜ rows — a planning session can die before flipping its row.

4. **Check the rules pointer.** The header's `Rules:` path must exist on disk. A missing path (an install cache that moved on update, or a header that predates the line) is drift: report the current real path of `../../docs/project-workflow.md` as the fix.

5. **Render** (Output). **Report drift, don't fix it** — a "⚠️ Drift" note under the tables.

## Sweep extension (explicit "sweep" only, new shape only)

Do everything in `status`, then, **with targeted string-replace edits only**:

- **Tracker-file drift** → fix the affected board row, Ladders row or detail line. A fact another live thread must learn → a Message; a project-level event with no owning row → one dated line in `archive/maintenance-log.md`.
- **Rules pointer** → rewrite a `Rules:` line whose path no longer exists to the current real path.
- **Stale tickets** → `advance-status` for tickets whose real state plainly advanced (work started → 🟡; work merged → 🟢). `close` only when the config says `done: agent`; under `done: owner` the ticket stays open and is reported "ready to close". An obsolete ticket → `cancel` with a one-line reason, then `reparent` it to `none`. A ticket can be ahead of reality because a person moved it: record the live status, flag the over-advance, never walk it backward.
- **Messages** → move fully-struck lines to `archive/messages.md`; strike-and-archive dead letters (addressee row 🟢/❌/⚪, or the thread has demonstrably ended). Never strike an ID for a live thread.
- **Ladders** → fix a stale step chip and the matching Ladders roll-up.
- **Open decisions** → move entries decided and already amended into their owning surface to `archive/decisions.md`.
- **Folded rows** → once a ⚪ or ❌ row's record lives in `decomposition.md` (Ledger note or Dropped) or `archive/`, remove the row and its detail.
- **Compression** → compress 🟢 journals and finished detail to residue; before a large rewrite, snapshot the file to `archive/<file>-<YYYY-MM-DD>-<reason>.md` (e.g. `archive/tracker-2026-11-05-pre-trim.md`). Only when no thread on the project is live; unsure → don't, and say why.
- **Worktree cleanup** → flag only. A branch counts as absorbed when its PR is MERGED and its own files match the merge commit (a diff against today's base and `git cherry` both mislead after squash merges and stacks). Delete only when the user said so in the same breath.
- **Memory** is out of scope.

Close `sweep` with one block: what reconciled clean, what drifted, what you changed (lines, ticket ops), and the cleanup you flagged.

## Output

```
## <Project name> (<ROOT>) — deliverable states

<one sentence: what the project builds>

| D | Ticket | What it delivers (plain English) | State | Situation |
|---|--------|----------------------------------|-------|-----------|
| **D1** | <KEY> | <plain clause a non-author understands> | 🟡 2/3 | <one short clause, or —> |
```

- Derive each outcome from the ticket title + the detail section; rephrase, don't echo the ticket title.
- **State** uses the six chips with any `n/m` roll-up; where the live ticket disagrees, show the ticket-derived truth and flag the drift. **Situation** carries the actionable nuance (awaiting approval, BEHIND base, CI red, gated on X, folded → D5:B2, ready for owner to close); `—` for settled rows.
- Then the **critical path** line, a **Queue** line (`<n> waiting; next: <handle>, <handle>`), the ladders table if any (`| Ladder | Umbrella | Steps done | Queued | State |`, steps done = 🟢 / all steps), `📬 <n> unread, oldest <date>` if Messages hold mail, a compact `| Ticket | What it is | State |` table for project-level tickets, **Next actions** re-ordered by what is actually unblocked, open decisions, and the **⚠️ Drift** footer.
- A board with no started rows still renders: the header row, the reconciled root, and the Queue head.

Terse and scannable — no raw JSON, no per-field dumps.

## Hard constraints

- **`status` is read-only everywhere** — no file edits, no ticket writes (read ops only), no `git`/`gh` mutations.
- **File writes only in `sweep`, only on a new-shape project's `tracker.md`, `ladders/*.md` and `archive/`** (targeted edits; `archive/` files may be created or appended), plus this skill's `learnings.md`. Never rewrite a tracker or ladder file wholesale; never edit `decomposition.md`, committed repo files, plan docs or memory.
- **Ticket writes only in `sweep`, only for plainly-stale tickets**, and never `close` under `done: owner`.
- **Never delete a worktree or branch unprompted.**
- **Read the tracker file first, every run.** No tracker file → say so (the effort may be below the project threshold) rather than inventing a board.
- **Reality wins.** When tickets or PRs disagree with the tracker file, trust them and surface the drift.

## Repeating

Read-only `status` is idempotent and safe to run on a schedule. `sweep` is not: run it deliberately, between sessions, with no thread live.

## Learnings

When a snapshot misreads a tracker file, mis-resolves a project, or misses a class of drift, append one dated line to this skill's `learnings.md` in the real skill folder (`### YYYY-MM-DD` then `- Observation. Source: <path / ticket / rule>.`). Only when the class recurs or the user flags a miss. A lesson about one tracker's behavior goes in that tracker's op sheet instead.
