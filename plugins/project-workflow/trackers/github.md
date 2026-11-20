# GitHub op sheet

Tickets are GitHub issues; children are sub-issues. Every step uses the `gh` CLI, version 2.97.0 or newer
(sub-issue flags and JSON fields). On an older `gh`, use the REST fallback noted under the op.

**Config** (`.project-workflow.yml`):

```yaml
tracker: github
github:
  repo: octo-org/octo-repo   # required: owner/name
  account: octocat           # optional: act as this gh account
```

**Every call** passes `-R <github.repo>`. When `github.account` is set, prefix every call with
`GH_TOKEN=$(gh auth token --user <github.account>)` so the right account is used even when another is active.
Credentials are `gh`'s own login (`gh auth login`); nothing else is needed.

## `key-format`

- In prose and tables: `#<n>` (for example `#12`).
- Root key in the folder name: `GH-<n>` (`scratch/GH-12-search-foundation/`). `GH-12` and `#12` are the same
  ticket in `github.repo`.
- PR body, reference only: `Refs #<n>`. PR body, closes on merge: `Closes #<n>`. Under `done: owner` never
  write `Closes`, `Fixes` or `Resolves` before a ticket number.

## `read-root`

```bash
gh issue view <n> -R <repo> --json number,title,body,state,stateReason,labels,issueType
```

A "Could not resolve" error means not found or no access.

## `read-ticket`

One ticket:

```bash
gh issue view <n> -R <repo> --json number,title,state,stateReason,labels,parent
```

Many tickets: one list call, then pick the numbers you need from the result.

```bash
gh issue list -R <repo> --state all --limit 500 --json number,title,state,stateReason,labels,parent
```

`--limit` is the pagination: raise it when the result has exactly that many rows. Status is `state` plus the
`pw:` labels (see `status-map`); resolution is `stateReason` (`COMPLETED`, `NOT_PLANNED`, or empty while open).

## `list-children`

```bash
gh issue view <n> -R <repo> --json subIssues --jq '.subIssues.nodes[] | {number, title, state}'
```

`subIssues.totalCount` larger than the number of nodes returned means the list was cut short: read the rest
with `gh api repos/<repo>/issues/<n>/sub_issues --paginate`. Read each child's labels with `read-ticket`.

REST fallback for an older `gh`: `gh api repos/<repo>/issues/<n>/sub_issues --paginate`.

## `cut`

```bash
gh issue create -R <repo> --title "<title>" --body-file <file> [--parent <n>] [--label bug]
```

Type `bug` adds the `bug` label; type `task` adds none. Omit `--parent` for a standalone ticket. The command
prints the new issue's URL; its last path segment is the number.

## `reparent`

```bash
gh issue edit <n> -R <repo> --parent <parent-n>     # move under a parent
gh issue edit <n> -R <repo> --remove-parent         # make it stand alone
```

## `comment`

```bash
gh issue comment <n> -R <repo> --body-file <file>
```

## `advance-status`

Status short of closing is carried by two labels. Create a label the first time it is needed:

```bash
gh label create "pw:in-progress" -R <repo> --color FBCA04 --description "Project workflow: work started" --force
gh label create "pw:ready-to-close" -R <repo> --color 0E8A16 --description "Project workflow: landed, owner to close" --force
```

- Target `🟡`: `gh issue edit <n> -R <repo> --add-label "pw:in-progress"`.
- Target `🟢` (landed, `done: owner`):
  `gh issue edit <n> -R <repo> --add-label "pw:ready-to-close" --remove-label "pw:in-progress"`.

A closed issue, or one already carrying `pw:ready-to-close`, is left alone and reported.

## `close`

```bash
gh issue close <n> -R <repo> --reason completed
gh issue edit <n> -R <repo> --remove-label "pw:in-progress" --remove-label "pw:ready-to-close"
```

## `cancel`

```bash
gh issue close <n> -R <repo> --reason "not planned" --comment "<reason>"
```

## `status-map`

| Issue state | Chip |
|---|---|
| open, no `pw:` label | ⬜ |
| open, `pw:in-progress` | 🟡 |
| open, `pw:ready-to-close` | 🟢 (landed, owner to close) |
| closed, `stateReason` `COMPLETED` | 🟢 |
| closed, `stateReason` `NOT_PLANNED` | ❌ |
