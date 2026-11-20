# Tracker op contract

The `pw-*` skills reach a ticket tracker only through the ops below. A skill names an op; the op sheet for the
repo's configured tracker (`<name>.md` beside this file) says how to perform it with concrete CLI or tool steps.
Adding a tracker means writing one sheet with every op heading here — no skill changes
(`../docs/adding-a-tracker.md`).

**What a sheet may read:** the repo config's `tracker`, `done`, and its own settings block
(`../docs/config.md`). Credentials come from the tracker CLI's login or from environment variables the sheet
names, never from config.

**Terms.** The *root* is the one ticket a project hangs off. A *child* is a ticket parented under the root (or
under another ticket). A *key* is the tracker's own identifier for a ticket.

Each op heading below is fixed: a sheet repeats it exactly.

## `key-format`

States three things: how a ticket key is written in prose and in tables; how the **root key** is written in the
project folder name (`scratch/<root>-<slug>/`), which must be filesystem-safe and stable; and how a PR body
references a ticket — one form that **only references** it and one form that **closes it on merge**. A skill
uses the closing form only when the config says `done: agent`.

## `read-root`

Input: a root key. Returns its title, description, type, and status, or "not found / no access". Read-only.

## `read-ticket`

Input: one key or a list of keys. Returns for each: title, status, resolution (why it is closed, when it is),
and parent key. A sheet says how to read many keys in as few calls as the tracker allows and how to follow
pagination to the end. Read-only.

## `list-children`

Input: a parent key. Returns every ticket parented under it, with the same fields as `read-ticket`. Skills diff
this against the keys a project's files name, to find tickets the board does not know. Read-only.

## `cut`

Input: a title, a description, a type (`task` or `bug`), and an optional parent key. Creates one ticket and
returns its key. With no parent it creates a standalone ticket.

## `reparent`

Input: a key and either a new parent key or `none`. Moves the ticket under that parent, or makes it stand alone.

## `comment`

Input: a key and comment text. Adds one comment.

## `advance-status`

Input: a key and a target chip (`🟡` in progress, or `🟢` landed). Moves the ticket's status toward that chip
**without closing it**. Under `done: owner` the `🟢` target means "landed, waiting for its owner to close": the
sheet says what marks that state. Never moves a ticket backward: a ticket already at or past the target is left
alone and reported.

## `close`

Input: a key. Closes the ticket as completed. A skill calls this only under `done: agent`; under `done: owner`
it calls `advance-status` with `🟢` and reports "ready to close" instead.

## `cancel`

Input: a key and a one-line reason. Closes the ticket as **won't do** (never as completed) and records the
reason. Used for obsolete tickets regardless of the `done` setting.

## `status-map`

A table from the tracker's ticket states to the workflow's chips: `⬜` not started, `🟡` in progress or in
review, `🟢` done (including "landed, waiting for its owner"), `❌` cancelled. `🔴` and `⚪` describe the work,
not the ticket, and have no mapping.
