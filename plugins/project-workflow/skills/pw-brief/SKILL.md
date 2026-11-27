---
name: pw-brief
description: Use when the user or an agent wants a decision brief for the project owner — phrases like "/pw-brief", "write a brief for this", "write a review page for this", "make me a page comparing the options", "put the current vs proposed design on a page", or "update the D2 brief". Writes one brief into the project's `briefs/` folder — markdown in a terminal session, a self-contained HTML page otherwise, and whichever format is explicitly asked for — under the terse contract (decision first, one line per item, latest state only, decided picks stay visible), overwriting an earlier revision of the same brief, and returns its absolute path.
---

# /pw-brief — write a decision brief into `briefs/`

`/pw-brief <project> <id> <topic>`. A brief is one file that puts a decision, a confirmation or a comparison in front of the project owner: markdown in a terminal session, a self-contained HTML page otherwise; an explicit request for a format wins. The substance comes from the current conversation (the design, options, evidence or decision the brief is for); this skill fixes where it goes and how it reads.

## Start (every run)

1. **Find the plugin.** Resolve the real path of the folder that holds this `SKILL.md`, following symlinks (`cd -P "<skill folder>" && pwd -P`). The plugin root is two levels above that real path.
2. **Read the rules** at `../../docs/project-workflow.md` and this skill's `learnings.md`.
3. **Read the repo config.** `main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')`. Neither `$main/.project-workflow.yml` nor `$main/.project-workflow.local.yml`, or no `tracker` key between them → stop with the opt-in message from the rules doc; write nothing. This skill makes no ticket calls, so it loads no op sheet.

## Flow

1. **Resolve the project** as `/pw-status` does: `scratch/*/tracker.md` under the main checkout, matched against the argument (name, root key or path). Several or none → list and ask.
2. **Pick the format**, `md` or `html`; the first match wins:
   1. The prompt explicitly asks for a format (markdown or md; HTML or a page) → that format.
   2. Revising an existing brief (same `<id>-<topic>`, either extension) → keep its format.
   3. Repo config `brief_format` (read as in Start step 3, the local file overriding) is `md` or `html` → that format. `auto` or unset falls through.
   4. The session's context holds a line containing `project-workflow brief format: md` or `project-workflow brief format: html` → that format.
   5. Otherwise markdown.
3. **Name the file** `briefs/<id>-<topic>.md` or `briefs/<id>-<topic>.html` per the format: `<id>` is the ticket key or task id the brief serves (`gh-12`, `d2-b3`, `cb3`), `<topic>` 2–6 kebab-case words; both lower-case. Create `briefs/` if missing.
4. **Existing file → revise in place.** Read it first; carry forward every decided pick (with its date and who decided) and drop superseded content. Never write `-v2` copies — the folder holds only the latest state. A revision keeps the existing format unless the prompt explicitly asks to switch. On a switch, read the old file, carry every decided pick into the new-format file, and delete the old file once the new one is written. Never keep both extensions of one brief.
5. **Write the brief** (contract and format rules below) and **return its absolute path**. After a format switch, also name the old path, so the caller repoints anything that cites it. Do not edit the tracker: the bridge, Queue line or open decision that needs the brief cites the path itself.

## Brief contract

- **Decision first.** The top block says what the owner must decide or confirm, and the recommended or decided pick; context comes after.
- **One line per item.** Options, findings and steps are list items or table rows, one line each; depth links to `docs/` notes or code paths instead of growing paragraphs.
- **Latest state only.** No revision history, no "previously" sections.
- **Decided picks stay visible.** A decided item shows `DECIDED <date> (<who>): <pick>` where it was asked, so a reader sees what is settled.
- **Concrete artifacts beside options.** When comparing options, put a small artifact next to each — a code excerpt, a diagram (ASCII in a `text` block in markdown; inline SVG or `<pre>` in HTML), a before/after table.

## Markdown rules

- Plain CommonMark with GFM tables and nothing else: no raw HTML, no images, no Mermaid, no front matter.
- Line 1 is `# <topic in plain words>`; the next paragraph is a meta line: project root, id, date written.
- Diagrams are ASCII inside ```` ```text ```` fenced blocks, at most 76 columns wide, drawn only with `+ - | > < v ^ * .`, letters, digits and spaces: no box-drawing characters and no backslashes, so alignment holds in any monospace font and every viewer shows each character.
- Keep tables to a few narrow columns; move long cell content into list items.
- Reads well as plain text and in a terminal markdown viewer (for example glow), which does not wrap code blocks.

## HTML rules

- One self-contained file: inline `<style>`, no `<script src>`, no web fonts, no remote images, no network fetches of any kind (pages are opened from disk, often offline). No Mermaid; draw diagrams as inline SVG or `<pre>` text.
- Reads in light and dark: colors as CSS variables on `:root`, redefined under `@media (prefers-color-scheme: dark)`; explicit `body` background; system font stack.
- `<title>` is the topic in plain words. A small meta line under the `<h1>`: project root, id, date written.
- Readable at laptop width and on a phone: `max-width` on the main column, tables in an `overflow-x:auto` wrapper.

## Hard constraints

- Writes only inside the resolved project's `briefs/`. The one removal allowed is the old file a format switch replaces.
- Never commits the brief and never copies it into a repo.

## Learnings

When a brief breaks the contract, misplaces a file or loses a decided pick on revision, append one dated line to this skill's `learnings.md` in the real skill folder (`### YYYY-MM-DD` then `- Observation. Source: <brief path>.`). Only when the class recurs or the user flags a miss.
