# project-workflow

<!-- tracker-specific -->

A workflow for efforts too big for one plan and one branch: several deliverables, several agent threads, one
root ticket. Each project lives in a gitignored `scratch/<root>-<short-name>/` folder whose `tracker.md` routes the
work, and four skills keep it honest against your ticket tracker.

| Skill | What it does |
|---|---|
| `/pw-open <root> [<short-name>] [<ticket>…]` | Creates the project folder from the templates and seeds its queue. Read-only on tickets. |
| `/pw-status <project> [sweep]` | Reconciles the tracker file against live tickets, PRs and worktrees and renders a plain-English board. `sweep` also fixes drift. |
| `/pw-land <project> <task-id>` | Lands a merged deliverable: flips its row, walks its ticket, cleans up its worktree. `/pw-land <project> close` closes and archives the project. |
| `/pw-brief <project> <id> <topic>` | Writes a self-contained HTML decision brief for the project owner. |

The rules every thread follows are in [`docs/project-workflow.md`](docs/project-workflow.md). Nothing injects
them into a session: each skill reads them when it starts, and every tracker file's header carries their path.

**Optional, Claude Code only:** the [`pw-board` mod](mod/) shows a project's tracker beside the chat as a board,
with a one-line summary above the prompt and a card under each brief. The skills work without it.

## Prerequisites

- **Compound Engineering.** The workflow's recipes are its `/ce-*` skills (`/ce-plan`, `/ce-work`, …).
- **`git`**, with worktrees.
- **`gh`**, logged in. Pull requests are read with it whichever ticket tracker you use.
- **Your ticket tracker's access**: for GitHub, `gh` 2.97.0 or newer; for Jira, an Atlassian MCP server in
  your agent, or `JIRA_EMAIL` and `JIRA_API_TOKEN` in your environment.

## Opt a repo in

Commit a `.project-workflow.yml` at the root of the repo's main checkout, and make sure `scratch/` is
gitignored:

```yaml
tracker: github
done: owner
github:
  repo: octo-org/octo-repo
```

```yaml
tracker: jira
done: owner
jira:
  site: example.atlassian.net
  project: ABC
```

`done` says who closes tickets. With `owner` (the default) agents advance and comment on a ticket but never
close it, and PR bodies reference tickets without closing keywords. With `agent`, `/pw-land` closes the ticket
when its work lands. An obsolete ticket is always cancelled as won't do, never closed as done.

Every key is listed in [`docs/config.md`](docs/config.md). A skill run in a repo without the file stops and
says what to add.

## Other trackers

The skills never name a tracker. They call a fixed set of ops ([`trackers/contract.md`](trackers/contract.md)),
and one markdown sheet per tracker says how to perform them. GitHub and Jira ship here. To add another, copy
[`trackers/_template.md`](trackers/_template.md) and follow [`docs/adding-a-tracker.md`](docs/adding-a-tracker.md).

## Where lessons go

Each skill appends recurring mistakes to the `learnings.md` in its own folder and reads that file at the start
of every run. Installed by symlink, that folder is your clone. Installed through the Claude marketplace, it is
the plugin cache and is lost on update: use the symlink install if you want to keep them.

## If another plugin already gives you `pw-*` skills

Two plugins with the same skill names both load, and a rules doc that one of them injects reaches every
session. In Claude Code, switch the other plugin off for a repo by setting it to `false` under
`enabledPlugins` in that repo's `.claude/settings.local.json`, or enable it per project instead of for your
whole user account.
