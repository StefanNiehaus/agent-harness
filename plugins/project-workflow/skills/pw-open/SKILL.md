---
name: pw-open
description: Use when the user wants to start a project — an effort of two or more deliverables or agent threads hung off one root ticket — phrases like "/pw-open", "/pw-open add offline sync to the mobile app", "/pw-open GH-12", "open a project for this epic", "start a project to fix the flaky login", or "set up the project folder and seed it with these tickets". Asks for a short description when none is given, cuts the root ticket from it in the repo's configured ticket tracker (or reads an existing root when the argument is just a ticket key), creates `scratch/<root>-<short-name>/` in the repo's main checkout with `tracker.md` and `decomposition.md` from the plugin's templates, and seeds the decomposition Queue with any existing tickets the user names, unnumbered. Refuses when the repo has not opted in or the project folder already exists; the root ticket is the only ticket it ever creates, and it never edits or moves one.
---

# /pw-open — start a project and its root ticket

`/pw-open [<what you want to accomplish>]`. The user describes the work; this skill cuts the root ticket, so they
never look up or type a key. `/pw-open <root key>` (just a key, such as `GH-12` or `ABC-123`) uses an existing
ticket as the root instead. Either way it writes two files and at most one ticket: no other ticket writes, no
worktree, no commit.

## Start (every run)

1. **Find the plugin.** Resolve the real path of the folder that holds this `SKILL.md`, following symlinks (`cd -P "<skill folder>" && pwd -P`). The plugin root is two levels above that real path. Resolve first: shortening `..` against a symlinked path lands in the wrong place.
2. **Read the rules** at `../../docs/project-workflow.md` and this skill's `learnings.md`.
3. **Read the repo config.** `main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')`; not in a git repo → stop and ask which repo the project lives in. Read `$main/.project-workflow.yml`, then apply any key set in `$main/.project-workflow.local.yml` over it. Neither file there, or no `tracker` key between them → stop with the opt-in message from the rules doc ("Opting a repo in"); create nothing.
4. **Load the op sheet** `../../trackers/<tracker>.md` for the config's `tracker`. No such sheet → stop, naming the missing file and `../../docs/adding-a-tracker.md`. Ops below are written as `op-name`; perform each exactly as the sheet says.

## Flow

1. **Get the description.** No argument → ask exactly this and wait:
   > Describe in brief what you want to accomplish, or describe your problem briefly.

   An argument that is only a ticket key in the sheet's `key-format` (in prose or folder form) → **existing-root
   mode**: skip step 3's `cut` and `read-root` that key instead. Anything else is the description. Tickets the user
   names to seed the Queue (in the description or after it, by key) are pulled out of it and kept apart.

2. **Validate everything before writing anything** — a failure here must leave no ticket behind.
   - `git -C "$main" check-ignore -q scratch/x` must succeed; if `scratch/` is not gitignored, stop and tell the user (the tracker file must never be committed).
   - The templates `../../templates/tracker.md` and `../../templates/decomposition.md` exist. Missing → stop and report; never hand-write the shape from memory.
   - `read-ticket` for each named ticket. Any not found → stop and name it.
   - Existing-root mode: `read-root` for the key. Not found or no access → stop.
   - Draft the root: a title of at most ~70 characters saying the outcome in plain words (for a problem, the fix: "Stop the login form timing out", not "Login broken"); type `bug` when the description reports something broken, else `task`; a body that is the user's description verbatim, then a blank line and `Root ticket for a project-workflow project.`
   - Short name: 2–4 kebab-case words from the root's title, unless the user gave one.
   - **Refuse** when any `$main/scratch/*/tracker.md` already has a title that plainly describes the same outcome, or, in existing-root mode, when any `$main/scratch/<ROOT>-*/` exists (match the key case-insensitively, since older folders may be lower-case): name it and point at `/pw-status`. Never overwrite.

3. **Cut the root** (description mode only): `cut` with the drafted title, body and type, no parent. The returned key is the root; `read-root` it once to confirm. The user's `/pw-open` with a description is the approval for this one ticket; ask nothing more. Root key for the folder: as the sheet's `key-format` writes it, never lower-cased. Directory: `$main/scratch/<ROOT>-<short-name>/`. If anything after this step fails, report the new key and the rerun line `/pw-open <ROOT>`, which picks the project up from that ticket without cutting another.

4. **Write `tracker.md`** from the template: fill the title (root title in plain words + root key and type), the absolute path line, `Created <today>`, the **Rules** line with the absolute real path of `../../docs/project-workflow.md`, the **Tracker** line (tracker name, root key, and the config's `done` value, `owner` when unset), and a one-line **Project shape** drafted from the root's title and description. Keep the `Shape: project-workflow/v1` header line exactly. Leave the status board with its header row and no deliverable rows (nothing has started), Next actions with one item (`Fill the end state and order the Queue in decomposition.md`), Open decisions `_(none open)_`, and drop the example D1 detail and invariants placeholders. Delete the template's guidance comments; keep the commented Ladders and Messages shapes.

5. **Write `decomposition.md`** from the template: title, a draft **End state** from the root's description (marked `(draft — owner to confirm)`), the **Number at start** working rule verbatim, an empty Ledger (header row only), and the Queue under **Deliverables:** with one unnumbered line per named ticket, in the order given:
   `` - `<handle>` — <plain-English outcome from the ticket title> · <KEY> ``
   The handle is a 1–3 word kebab-case name for the outcome. A seeded ticket keeps its current parent; it moves under the root, and takes its number in the Ledger, only when its work starts — that is the dispatching agent's step, not this skill's. Leave Not in this project and Dropped with their headers only.

6. **Report**: the root key with its title and whether it was cut or already existed, the two absolute paths, the seeded handles with their keys, and the next step — confirm the end state and Queue order, then dispatch the first Queue item with the rules doc's formula once it is started.

## Hard constraints

- Writes only `tracker.md` and `decomposition.md` inside the new project directory (and creates that directory). No `docs/`, `briefs/`, `proof/`, `ladders/` or `archive/` — each appears on first use.
- Creates at most one ticket — the root, through `cut` with no parent — and only after every check in step 2 has passed. Otherwise uses only the read ops (`read-root`, `read-ticket`). Never edits, advances or reparents a ticket.
- Never overwrites an existing project directory, and never opens a second project for the same root.
- Writes nothing at all, in the repo or the ticket tracker, in a repo that has not opted in.

## Learnings

When an open misreads the description or the root, cuts a poor root title, picks a bad short name or handle, or produces a tracker `/pw-status` cannot read, append one dated line to this skill's `learnings.md` in the real skill folder (`### YYYY-MM-DD` then `- Observation. Source: <path / ticket>.`). Only when the class recurs or the user flags a miss. A lesson about one tracker's behavior goes in that tracker's op sheet instead.
