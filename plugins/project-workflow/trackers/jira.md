# Jira op sheet

Tickets are Jira issues; children are issues whose `parent` is the root (an epic's stories, or a ticket's
sub-tasks).

**Config** (`.project-workflow.yml`):

```yaml
tracker: jira
jira:
  site: example.atlassian.net   # required: the site host
  project: ABC                  # required: project key for new tickets
  land_status: In Review        # optional: where agents walk a landed ticket under done: owner
```

**Two routes.** Use whichever the session has, and use the same one for a whole run.

- **MCP route** — when the session has an Atlassian MCP server, use its Jira tools: get issue, search with JQL,
  get transitions, transition issue, edit issue, create issue, add comment. Tool names differ by installation,
  so match by what the tool does. Most take a `cloudId`: look it up once per run from `jira.site` with the
  server's "accessible resources" tool and reuse it.
- **REST route** — otherwise call `https://<jira.site>/rest/api/3` with `curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN"
  -H "Accept: application/json"`. Both variables come from the environment; if either is unset, stop and say
  so. Never write either value into a file or a command you echo.

A 401 or 403 on any call: stop and report. Tokens expire and scopes change.

## `key-format`

- In prose, tables and the folder name: the key exactly as Jira writes it, upper case (`ABC-123`,
  `scratch/ABC-123-export-rework/`). Never lower-case it in a folder name; branch names may.
- PR body, reference only: `Refs ABC-123`. Jira has no merge-closes-ticket keyword of its own, so the closing
  form is the same reference, and under `done: agent` the skill calls `close` after the merge.

## `read-root`

- MCP: get issue `<KEY>` with fields `summary,description,issuetype,status`.
- REST: `GET /issue/<KEY>?fields=summary,description,issuetype,status`.

A 404 means not found or no access.

## `read-ticket`

Read many keys in one search:

- JQL: `key in (ABC-1, ABC-2, …) ORDER BY key ASC`, fields `summary,status,resolution,parent`.
- MCP: the JQL search tool. REST: `POST /search/jql` with `{"jql": "...", "fields": [...], "maxResults": 100}`.

**Follow pagination to the end.** A page can hold as few as ten issues even for a short key list: keep
requesting with the returned `nextPageToken` until the response says it is the last page. When a large result
is saved to a file instead of shown, extract `key`, `status` and `resolution` from that file rather than
searching again.

Status is `fields.status.statusCategory.key` (`new`, `indeterminate`, `done`) plus `fields.status.name`;
resolution is `fields.resolution.name`.

## `list-children`

JQL `parent = <KEY> ORDER BY key ASC`, same fields and pagination as `read-ticket`. This finds tickets that
were cut under the root but never written into the project's files.

## `cut`

- MCP: create issue in project `jira.project` with the summary, description, and issue type (`Task` or `Bug`);
  pass `parent` when a parent key was given.
- REST: `POST /issue` with
  `{"fields": {"project": {"key": "<project>"}, "summary": "...", "issuetype": {"name": "Task"}, "parent": {"key": "<PARENT>"}}}`
  plus a `description` in Atlassian Document Format; omit `parent` for a standalone ticket.

Returns the new key.

## `reparent`

- MCP: edit issue, field `parent` set to `{"key": "<PARENT>"}`, or to `null` to make it stand alone.
- REST: `PUT /issue/<KEY>` with `{"fields": {"parent": {"key": "<PARENT>"}}}` or `{"fields": {"parent": null}}`.

## `comment`

- MCP: add comment to `<KEY>`.
- REST: `POST /issue/<KEY>/comment` with the body in Atlassian Document Format.

## `advance-status`

Jira moves a ticket only along the transitions its workflow offers from the current status, and a transition's
id depends on that status. So for every hop: **read the available transitions, pick one, apply it, then read
the transitions again** before the next hop.

- MCP: get transitions for `<KEY>`, then transition issue with the chosen id.
- REST: `GET /issue/<KEY>/transitions`, then `POST /issue/<KEY>/transitions` with `{"transition": {"id": "<id>"}}`.

Targets:

- `🟡`: when the ticket's status category is `new`, take a transition whose destination category is
  `indeterminate`. Already `indeterminate` or `done`: leave it and report.
- `🟢` (landed, `done: owner`): when `jira.land_status` is set, walk hop by hop until the status name equals
  it, choosing at each hop the transition that leads toward it and never one whose destination category is
  `done`. When it is not set, or no path reaches it, leave the status alone and add the label
  `pw-ready-to-close` (MCP: edit issue, `labels` add; REST: `PUT /issue/<KEY>` with
  `{"update": {"labels": [{"add": "pw-ready-to-close"}]}}`).

Never walk a ticket backward. A ticket can be ahead of the work, because a person moved it: record the live
status, report the over-advance, and leave it.

## `close`

Take a transition whose destination status category is `done` and whose name is not a cancel or won't-do
transition, following the read-apply-read rule above. When the workflow offers no such transition from the
current status, walk toward one hop by hop; when none can be reached, stop and report the status it is stuck
at. Remove the `pw-ready-to-close` label if present.

## `cancel`

Take the workflow's cancel transition (commonly named Cancel, Won't Do, or Rejected) and set the resolution to
the site's won't-do value when the transition asks for one. Then add the reason with `comment`, and clear the
ticket's parent with `reparent` to `none` so a cancelled ticket does not count against the root. Never use a
plain Done transition for an obsolete ticket.

## `status-map`

| Jira state | Chip |
|---|---|
| status category `new` (To Do) | ⬜ |
| status category `indeterminate` (In Progress) | 🟡 |
| status name equals `jira.land_status`, or label `pw-ready-to-close` | 🟢 (landed, owner to close) |
| status category `done`, resolution is not a won't-do value | 🟢 |
| status category `done`, resolution is a won't-do value (Won't Do, Cancelled, Rejected) | ❌ |
