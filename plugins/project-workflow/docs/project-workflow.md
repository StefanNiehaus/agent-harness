# Project workflow — rules

The plugin's only rules doc. Nothing injects it: each `pw-*` skill reads it when it starts, and a thread
dispatched from a tracker finds it through the `Rules:` line in the tracker header. Procedures live in the
`pw-*` skills (index at the end); templates in `../templates/` (`tracker.md`, `decomposition.md`,
`ladder.md`); ticket-tracker steps in `../trackers/` (one op sheet per tracker).

## Always work on a worktree

Every artifact you produce for a repo — docs and plans as much as code — goes on a git worktree at
`.worktrees/<branch>`, created **before** you write anything: inside a `.worktrees/` checkout, work there; in the
main checkout, create one first. Several agents run against one repo at once; isolation keeps them apart. Read-only
or conversational work needs none; the repo's gitignored `scratch/` is free for throwaway notes. **Project
carve-out:** a project's pre-work (ideation, brainstorms, plans) is born in its `docs/<kind>/` with no worktree;
`/ce-work` creates the deliverable's first worktree, copies those docs onto the branch and repoints the bridge.

**Planning → implementation.** When `/ce-plan` has written a plan, run `/ce-work` in a fresh session — the plan on
disk is the handoff, not the planning conversation — and commit the plan doc on the worktree branch.

## Projects

A **project** is any effort split into 2+ deliverables or worked by 2+ agent threads. It hangs off a **root**
(one ticket in the repo's tracker: an epic, a parent issue, or a single ticket) and lives in a gitignored
`scratch/<root>-<slug>/` in the repo's main checkout. A **ticket** is any item in the tracker; the **tracker** is
the ticket system the repo's config names; the tracker's own grouping of tickets is always written **tracker
project**. A **deliverable** (`D1`) is the dispatch grain, with sub-deliverables `D1:B2`; a **thread** is one
agent's stint on a deliverable or ladder step; a **recipe** is its entry and exit `/ce-*` skills written as
slash-commands. Work waits unnumbered in the Queue and takes its D or B number in the Ledger when it starts — its
ticket moves under the root (or is cut) then. Below the threshold (one deliverable, one thread) skip all this: a
plan doc and a worktree suffice.

## Opting a repo in

A repo opts in with a `.project-workflow.yml` at the root of its main checkout, naming its tracker and that
tracker's settings (`config.md` beside this file lists every key). A user who cannot commit that file can opt in
alone with a gitignored `.project-workflow.local.yml` in the same place, which otherwise only overrides keys. A
`pw-*` skill run where neither file names a `tracker` writes nothing and answers:

> This repo has not opted in to the project workflow. Add `.project-workflow.yml` to the root of the main
> checkout with at least `tracker: <name>` and that tracker's settings block — see `<absolute path of config.md>`.

A config naming a tracker that has no op sheet stops the same way, naming the missing
`trackers/<name>.md` and the adding-a-tracker guide.

## Project folder

```
scratch/<KEY>-<slug>/        # root key exactly as the tracker's op sheet writes it (GH-12, ABC-123), then a 2-4 word kebab slug
├── tracker.md               # router: board, ladders, Messages, next actions, open decisions, bridges, invariants
├── decomposition.md         # scope of record: end state, rules, Ledger, Queue, Not in this project, Dropped
├── ladders/<NAME>.md        # one named queue of small one-PR fixes under one umbrella ticket
├── docs/                    # plans/ ideation/ reviews/ · brainstorms/ (legacy, read-only)
│                            #   depth notes: concept- grounding- findings- future- (no other prefixes)
├── pages/<id>-<topic>.html  # HTML review pages for the owner (`/pw-page`)
├── proof/<id>-<topic>/      # one verification: README.md · harness/ · inputs/ · runs/<run>/
└── archive/                 # decisions.md · maintenance-log.md · messages.md · <file>-<YYYY-MM-DD>-<reason>.md
```

A folder or section exists only once something occupies it, and nothing named `tmp` lives in a project. Plans keep
CE's `YYYY-MM-DD-HHMM-<type>-<topic>-plan.md` so `/ce-work` copies them unchanged (`/ce-brainstorm` writes there
too); depth notes are `<kind>-<YYYY-MM-DD>-<topic>.md`, each with one pointer line from the tracker or decomposition.
`<id>` is the ticket or task an item serves (`gh-12`, `d2-b3`, `cb3`), never a date. **`pages/`** is flat by default;
a page follows the terse contract: decision first, one line per item, latest state only, decided picks stay visible;
a revision overwrites its file. **`proof/<id>-<topic>/`** holds one verification: a README stating the result (MATCH /
DIFFERENT, with a broken control when one can be built) and how to re-run it; `harness/` files enter the repo only
for a run and are never committed; `inputs/` holds captures, baselines and config snapshots; `runs/<run>/` holds
per-run outputs. **`archive/`** holds decided open-decisions, the maintenance log, read Messages, and pre-rewrite
snapshots of any file.

**One home per fact.** The tracker file routes and never duplicates. The ticket tracker owns ticket status; the
worktree/PR owns the artifact; `decomposition.md` owns scope; `docs/` owns depth; `docs/solutions/` owns ratified
repo lessons. If one fact appears on two surfaces, one of them is wrong. Ticket-facing prose (PRs, comments) cites
ticket keys, never `D4`.

**Status chips** (one vocabulary everywhere): ⬜ not started · 🟡 in progress / in review · 🟢 done / deployed · 🔴
blocked / gated · ⚪ folded / absorbed (with pointer) · ❌ cancelled / won't do. A status lives only in its table
cell. Cell grammar: `<chip> [<done>/<total>] [— <short clause, ≤ ~12 words>]`.

**Routing new work:** fits a started deliverable → a `Bn` row in its detail (or its Queue group); a new outcome →
a Queue line in `decomposition.md`; a small one-PR fix that fits nothing → a ladder's queue; not actionable here →
a `future-`/`findings-` note plus one pointer line; out of scope → Not in this project or Dropped with its reason.
Nothing accumulates in the tracker's hot path.

## Dispatch and threads

Dispatch in a fresh session with a ≤2-line pointer, never a hand-off prompt:
`/<entry skill> <project>, <task id> — first read the tracker at <absolute tracker path>` — skill ← the recipe ·
project and path ← the tracker header · task id ← the row (`D1`, `CB3`, `D5:B2`). The bridge (repo, base branch,
pre-work location, scope fence) carries the rest; if you are restating it, stop — fix the bridge, not the prompt.
**CE interop:** when a CE skill offers a launch, work or goal prompt (or to start the next skill in-session) for
project work, this line *is* that prompt — write any remaining scope into the bridge first, then point.
**Cross-repo:** run the line from the bridge's repo; the absolute tracker path lets the fresh session read this
repo's scratch. **Subagents:** a subagent started mid-session has read neither the tracker nor this doc — name the
tracker path and this doc's absolute path when you hand one project work.

Work only your own surface (your row and detail, or your ladder file), with targeted edits — never rewrite the
tracker. Decisions go to Open decisions; facts another live thread needs go to **Messages**:
`<YYYY-MM-DD> <FROM>→<TO>: <one-liner> [→ <pointer>]` with row IDs, `owner` or `all`; each reader strikes its own
ID and the last reader moves the line to `archive/messages.md`. One live thread writes to its own surface instead.

**Live-thread safety.** Running agents re-read only the tracker, so broadcast a mid-project rule change as a
Message. Compression, archive moves and memory rewrites run only when no thread on the project is live — a running
agent can rewrite a section from stale context and clobber them.

**Memory.** Where the agent keeps a memory store: no per-project entries; discovery is the glob
`<repo>/scratch/*/tracker.md`. Memory keeps only residue that outlives one project; repo lessons go to
`docs/solutions/`.

**Tickets.** Agents do their own ticket writes, and only through the ops in `../trackers/contract.md` as the
configured tracker's sheet spells them out. Who closes a ticket is the repo's `done` setting: with `done: owner`
(the default) an agent advances and comments but never closes a ticket or moves it to done, and a PR body
references its ticket without a closing keyword; with `done: agent` the PR body may close it and `/pw-land` may
close it. An obsolete ticket is always cancelled through the sheet's `cancel` op (won't do), never closed as done.

## Skills

- `/pw-open <root> [<slug>] [<ticket>…]` — create the project folder from the templates; seed the Queue.
- `/pw-land <project> <task-id>` — land a deliverable or ladder step in hot context: compound, row flip, ticket
  walk, worktree cleanup last. `/pw-land <project> close` — close the project: ticket-or-drop table, owner
  approval, archive.
- `/pw-page <project> <id> <topic>` — write a review page into `pages/` and return its path.
- `/pw-check <project> [sweep]` — reconciled read-only snapshot; `sweep` adds maintenance writes.

Each skill starts the same way: resolve the real path of its own skill folder and walk up two levels to the
plugin, read this doc and its own `learnings.md`, read the repo config, then load the configured tracker's op
sheet. Compound Engineering (`/ce-*`) is a prerequisite: the recipes are its skills.
