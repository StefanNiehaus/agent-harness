# Adding a tracker

<!-- tracker-specific -->

The skills never name a tracker. They call the ops in `../trackers/contract.md`, and one markdown **op sheet**
per tracker says how to perform each op. To add a tracker you write one sheet. No skill changes.

1. Copy `../trackers/_template.md` to `../trackers/<name>.md`.
2. Fill in every op section with steps an agent can run as written: exact CLI commands or the tool calls to make.
3. Decide which settings the sheet needs and document them at the top as a `<name>:` config block.
4. In a repo, set `tracker: <name>` and that block in `.project-workflow.yml`.
5. Run `tests/run` from the repo root. It fails if your sheet is missing any op heading from the contract.

GitHub (`github.md`) and Jira (`jira.md`) ship with the plugin. Azure DevOps is the next adapter planned.

## Worked example: Linear

This walks through the decisions for a Linear sheet. It is an illustration, not a shipped sheet: write the real
steps against the Linear access you have (its MCP server, or its GraphQL API with a personal API key).

**Config block.** Linear tickets belong to a team, so the sheet needs the team key:

```yaml
tracker: linear
linear:
  team: ENG
```

**Access.** State one route at the top, for example: "Use the Linear MCP server's issue tools. Without it, call
`https://api.linear.app/graphql` with `Authorization: $LINEAR_API_KEY`; stop if the variable is unset."

| Op | What the Linear sheet says |
|---|---|
| `key-format` | Keys are the identifier Linear shows (`ENG-123`), used as-is in prose and in the folder name. A PR body references a ticket with `Refs ENG-123`; Linear's magic words (`Fixes ENG-123`) close it on merge, so that is the closing form. |
| `read-root` | Fetch the issue by identifier: title, description, state, and whether it is a project or a parent issue. |
| `read-ticket` | One issue by identifier; many with a filter on identifiers, paging with the cursor until `hasNextPage` is false. Status is `state.type`, parent is `parent.identifier`. |
| `list-children` | The issue's `children` connection, paged the same way. |
| `cut` | Create an issue in the configured team with a title and description; set `parentId` when a parent was given; add the Bug label for type `bug`. The response carries the new identifier. |
| `reparent` | Update the issue's `parentId` to the new parent's id, or to null to make it stand alone. |
| `comment` | Create a comment on the issue. |
| `advance-status` | 🟡: move to the team's first state of type `started`. 🟢 under `done: owner`: move to the team's review state if it has one, otherwise add a `pw-ready-to-close` label. Never move to a `completed` state here. |
| `close` | Move to the team's state of type `completed`. |
| `cancel` | Move to the team's state of type `canceled` and add the reason as a comment. |
| `status-map` | `backlog` and `unstarted` → ⬜ · `started` → 🟡 · review state or `pw-ready-to-close` label → 🟢 · `completed` → 🟢 · `canceled` → ❌ |

With the sheet saved as `trackers/linear.md` and the config above in a repo, `/pw-open ENG-123` reads the root
through `read-root` and `/pw-status` reconciles through `read-ticket` and `list-children`. Neither skill file
changed.

## What makes a good sheet

- **Runnable as written.** Each op gives the command or call, not a description of one.
- **Pagination spelled out.** Say how to know a result was cut short and how to get the rest.
- **The waiting state is real.** Under `done: owner` a landed ticket stays open; the sheet must name the
  status, label or field that marks it, and `status-map` must map that marker to 🟢.
- **Lessons live here.** When a tracker surprises you (a rate limit, an id that changes, a field that lies),
  write it into the sheet, not into a skill.
