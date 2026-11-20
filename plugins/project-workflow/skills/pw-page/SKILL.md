---
name: pw-page
description: Use when the user or an agent wants a review page for the project owner — phrases like "/pw-page", "write a review page for this", "make me a page comparing the options", "put the current vs proposed design on a page", or "update the D2 review page". Writes one self-contained HTML page into the project's `pages/` folder under the terse contract (decision first, one line per item, latest state only, decided picks stay visible), overwriting an earlier revision of the same page, and returns its absolute path.
---

# /pw-page — write a review page into `pages/`

`/pw-page <project> <id> <topic>`. The substance comes from the current conversation (the design, options, evidence or decision the page is for); this skill fixes where it goes and how it reads.

## Start (every run)

1. **Find the plugin.** Resolve the real path of the folder that holds this `SKILL.md`, following symlinks (`cd -P "<skill folder>" && pwd -P`). The plugin root is two levels above that real path.
2. **Read the rules** at `../../docs/project-workflow.md` and this skill's `learnings.md`.
3. **Read the repo config.** `main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')`. No `$main/.project-workflow.yml` → stop with the opt-in message from the rules doc; write nothing. This skill makes no ticket calls, so it loads no op sheet.

## Flow

1. **Resolve the project** as `/pw-check` does: `scratch/*/tracker.md` under the main checkout, matched against the argument (name, root key or path). Several or none → list and ask.
2. **Name the file** `pages/<id>-<topic>.html`: `<id>` is the ticket key or task id the page serves (`gh-12`, `d2-b3`, `cb3`), `<topic>` 2–6 kebab-case words; both lower-case. Create `pages/` if missing.
3. **Existing file → revise in place.** Read it first; carry forward every decided pick (with its date and who decided) and drop superseded content. Never write `-v2` copies — the folder holds only the latest state.
4. **Write the page** (contract below) and **return its absolute path**. Do not edit the tracker: the bridge, Queue line or open decision that needs the page cites the path itself.

## Page contract

- **Decision first.** The top block says what the owner must decide or confirm, and the recommended or decided pick; context comes after.
- **One line per item.** Options, findings and steps are list items or table rows, one line each; depth links to `docs/` notes or code paths instead of growing paragraphs.
- **Latest state only.** No revision history, no "previously" sections.
- **Decided picks stay visible.** A decided item shows `DECIDED <date> (<who>): <pick>` where it was asked, so a reader sees what is settled.
- **Concrete artifacts beside options.** When comparing options, put a small artifact next to each — a code excerpt, an inline SVG or `<pre>` diagram, a before/after table.

## HTML rules

- One self-contained file: inline `<style>`, no `<script src>`, no web fonts, no remote images, no network fetches of any kind (pages are opened from disk, often offline). No Mermaid; draw diagrams as inline SVG or `<pre>` text.
- Reads in light and dark: colors as CSS variables on `:root`, redefined under `@media (prefers-color-scheme: dark)`; explicit `body` background; system font stack.
- `<title>` is the topic in plain words. A small meta line under the `<h1>`: project root, id, date written.
- Readable at laptop width and on a phone: `max-width` on the main column, tables in an `overflow-x:auto` wrapper.

## Hard constraints

- Writes only inside the resolved project's `pages/`.
- Never commits the page and never copies it into a repo.

## Learnings

When a page breaks the contract, misplaces a file or loses a decided pick on revision, append one dated line to this skill's `learnings.md` in the real skill folder (`### YYYY-MM-DD` then `- Observation. Source: <page path>.`). Only when the class recurs or the user flags a miss.
