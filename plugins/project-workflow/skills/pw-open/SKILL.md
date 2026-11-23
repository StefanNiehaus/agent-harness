---
name: pw-open
description: Use when the user wants to start a project — an effort of two or more deliverables or agent threads hung off one root ticket — phrases like "/pw-open GH-12", "/pw-open ABC-123", "open a project for this epic", "start a tracker for issue 12", or "set up the project folder and seed it with these tickets". Reads the root ticket (read-only) from the repo's configured ticket tracker, creates `scratch/<root>-<short-name>/` in the repo's main checkout with `tracker.md` and `decomposition.md` from the plugin's templates, and seeds the decomposition Queue with any existing tickets the user names, unnumbered. Refuses when the repo has not opted in or the project folder already exists; never creates, edits or moves a ticket.
---

# /pw-open — create a project folder for a root ticket

`/pw-open <root> [<short-name>] [<ticket>…]`. This skill writes two files and nothing else: no ticket writes, no worktree, no commit.

## Start (every run)

1. **Find the plugin.** Resolve the real path of the folder that holds this `SKILL.md`, following symlinks (`cd -P "<skill folder>" && pwd -P`). The plugin root is two levels above that real path. Resolve first: shortening `..` against a symlinked path lands in the wrong place.
2. **Read the rules** at `../../docs/project-workflow.md` and this skill's `learnings.md`.
3. **Read the repo config.** `main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')`; not in a git repo → stop and ask which repo the project lives in. Read `$main/.project-workflow.yml`, then apply any key set in `$main/.project-workflow.local.yml` over it. Neither file there, or no `tracker` key between them → stop with the opt-in message from the rules doc ("Opting a repo in"); create nothing.
4. **Load the op sheet** `../../trackers/<tracker>.md` for the config's `tracker`. No such sheet → stop, naming the missing file and `../../docs/adding-a-tracker.md`. Ops below are written as `op-name`; perform each exactly as the sheet says.

## Flow

1. **Validate everything before writing anything.**
   - `read-root` for the root. Not found or no access → stop; no directory is created.
   - `read-ticket` for each named ticket. Any not found → stop and name it; nothing is created.
   - Root key for the folder: as the sheet's `key-format` writes it, never lower-cased. Short name: the argument if given, else 2–4 kebab-case words from the root's title. Directory: `$main/scratch/<ROOT>-<short-name>/`.
   - **Refuse** when that directory exists, or when any `$main/scratch/<ROOT>-*/` exists (the root already has a project; match the key case-insensitively, since older folders may be lower-case): name it and point at `/pw-status`. Never overwrite.
   - `git -C "$main" check-ignore -q scratch/x` must succeed; if `scratch/` is not gitignored, stop and tell the user (the tracker file must never be committed).

2. **Locate the templates** at `../../templates/tracker.md` and `../../templates/decomposition.md`. Missing → stop and report; never hand-write the shape from memory.

3. **Write `tracker.md`** from the template: fill the title (root title in plain words + root key and type), the absolute path line, `Created <today>`, the **Rules** line with the absolute real path of `../../docs/project-workflow.md`, the **Tracker** line (tracker name, root key, and the config's `done` value, `owner` when unset), and a one-line **Project shape** drafted from the root's title and description. Keep the `Shape: project-workflow/v1` header line exactly. Leave the status board with its header row and no deliverable rows (nothing has started), Next actions with one item (`Fill the end state and order the Queue in decomposition.md`), Open decisions `_(none open)_`, and drop the example D1 detail and invariants placeholders. Delete the template's guidance comments; keep the commented Ladders and Messages shapes.

4. **Write `decomposition.md`** from the template: title, a draft **End state** from the root's description (marked `(draft — owner to confirm)`), the **Number at start** working rule verbatim, an empty Ledger (header row only), and the Queue under **Deliverables:** with one unnumbered line per named ticket, in the order given:
   `` - `<handle>` — <plain-English outcome from the ticket title> · <KEY> ``
   The handle is a 1–3 word kebab-case name for the outcome. A seeded ticket keeps its current parent; it moves under the root, and takes its number in the Ledger, only when its work starts — that is the dispatching agent's step, not this skill's. Leave Not in this project and Dropped with their headers only.

5. **Report**: the two absolute paths, the seeded handles with their keys, and the next step — confirm the end state and Queue order, then dispatch the first Queue item with the rules doc's formula once it is started.

## Hard constraints

- Writes only `tracker.md` and `decomposition.md` inside the new project directory (and creates that directory). No `docs/`, `briefs/`, `proof/`, `ladders/` or `archive/` — each appears on first use.
- Uses only the read ops (`read-root`, `read-ticket`). Never creates, edits, advances or reparents a ticket.
- Never overwrites an existing project directory, and never opens a second project for the same root.
- Writes nothing at all in a repo that has not opted in.

## Learnings

When an open misreads the root, picks a bad short name or handle, or produces a tracker `/pw-status` cannot read, append one dated line to this skill's `learnings.md` in the real skill folder (`### YYYY-MM-DD` then `- Observation. Source: <path / ticket>.`). Only when the class recurs or the user flags a miss. A lesson about one tracker's behavior goes in that tracker's op sheet instead.
