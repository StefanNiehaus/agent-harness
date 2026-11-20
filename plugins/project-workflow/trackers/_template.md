# <Tracker name> op sheet

Copy this file to `<name>.md`, fill in every section, and set `tracker: <name>` in a repo's
`.project-workflow.yml`. The op headings are fixed by `contract.md`: keep each one exactly as written.

**Config** (`.project-workflow.yml`): <the keys this sheet reads from its own `<name>:` block, with an example>.

**Access:** <the CLI or tools every step uses, how the user logs in, and which environment variables hold
credentials, if any. Say what to do on an authentication failure.>

## `key-format`

<How a key is written in prose; how the root key is written in the folder name; the PR-body form that only
references a ticket and the form that closes it on merge.>

## `read-root`

<The step that returns a root's title, description, type and status, and what "not found" looks like.>

## `read-ticket`

<The step for one key, the step for many keys, and how to follow pagination to the end. Say which fields are
status, resolution and parent.>

## `list-children`

<The step that lists every ticket under a parent.>

## `cut`

<The step that creates a ticket from a title, description, type (task or bug) and optional parent, and how to
read the new key from its output.>

## `reparent`

<The step that moves a ticket under a parent, and the step that makes it stand alone.>

## `comment`

<The step that adds one comment.>

## `advance-status`

<How to mark a ticket in progress (🟡), and how to mark it landed and waiting for its owner (🟢) without
closing it. Say what marks the waiting state: a status, a label, or a field.>

## `close`

<The step that closes a ticket as completed.>

## `cancel`

<The step that closes a ticket as won't do, never as completed, and records a reason.>

## `status-map`

| <Tracker> state | Chip |
|---|---|
| <not started> | ⬜ |
| <in progress or in review> | 🟡 |
| <landed, owner to close> | 🟢 |
| <done> | 🟢 |
| <cancelled / won't do> | ❌ |
