# pw-board

An optional Claude Code mod that shows a project-workflow tracker while you work. It only reads files: the
skills write the tracker, and the board shows it. Nothing in the skills depends on it.

- **Board pane** (`/pw-board`): the project's deliverables with their plain-English outcomes and state chips,
  a "Needs you" box for open decisions with a button to open each brief, then the critical path, next actions,
  the Queue and unread Messages. **Reconcile** runs `/pw-status <project>` (read-only); **Sweep** runs
  `/pw-status <project> sweep` (may write). With several projects, a picker chooses one.
- **Band above the prompt:** the active project's chips, open decisions and unread messages, with Board and
  Hide buttons. It hides itself when the repo has no project.
- **Brief card:** when `/pw-brief` writes `scratch/<project>/briefs/<id>-<topic>.html`, a card under that tool
  call shows the brief's title and an **Open** button.

It finds projects in `scratch/*/tracker.md` under the repo's main checkout, rereads a tracker when its file
changes (checked every 4 seconds and after each turn), and draws a board only for trackers with the
`Shape: project-workflow/v1` line. An older tracker gets a pointer to `/pw-land <project> close` instead.

## Install

Mods are an early-access Claude Code feature. Point Claude Code at this folder in your clone:

- **For one session:** `claude --plugin-dir <clone>/plugins/project-workflow/mod`
- **For every session, the desktop app included:** add the folder to `CLAUDE_CODE_PLUGIN_DIRS` in the `env`
  block of `~/.claude/settings.json`:

  ```json
  { "env": { "CLAUDE_CODE_PLUGIN_DIRS": "<clone>/plugins/project-workflow/mod" } }
  ```

Claude Code writes generated type files into `.claude-plugin/types/` when it loads the mod. They are gitignored.

## Changing it

- The parser is `hooks/tracker.ts`; it reads the layout of [`templates/tracker.md`](../templates/tracker.md) and
  the Queue section of [`templates/decomposition.md`](../templates/decomposition.md). When a template changes,
  update the parser and the sample tracker in `hooks/tracker.test.ts` with it.
- `claude plugin validate <this folder>` checks the manifest and module; `claude plugin test <this folder>`
  runs the parser tests.
