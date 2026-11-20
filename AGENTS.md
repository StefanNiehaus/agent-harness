# agent-harness

A collection of opt-in plugins under `plugins/<name>/`. Each plugin is a Claude Code plugin and a set of
portable Agent Skills folders at once, built from one tree.

## Rules for every plugin

`tests/run` enforces the first two. Run it before every commit.

- **No personal or employer values.** No employer names, tracker sites, cloud ids, or email addresses, in
  any tracked file. Anything specific to a user or a repo comes from config. Keep a private list of the
  strings you must never commit in a gitignored `.denylist.local` (one pattern per line) and the test will
  search for them too.
- **Skills are portable.** A `SKILL.md` carries only the open Agent Skills frontmatter fields (`name`,
  `description`, and optionally `license`, `compatibility`, `metadata`, `allowed-tools`), and its `name`
  matches its folder. A skill body, rules doc, or template names no agent-specific tool, hook, or
  environment variable. A plugin may ship agent-specific extras, but nothing may depend on them.
- **A skill finds its plugin from its own folder.** It resolves the real path of its skill directory and
  walks up two levels. Never hard-code an install path.
- **Nothing installs unless the user names it.** `bin/install` with no plugin argument installs nothing.

## Where an observation goes

- A skill misfires: one dated line in that skill's `learnings.md`. A behavior change: edit its `SKILL.md`.
- A rule is missing or wrong: edit the plugin's rules doc.
- A file shape changes: edit the template, and bump its `Shape:` version when old copies stop being readable.

## Tests

`tests/run` executes every `tests/*.test.sh`. The tests are plain bash and need `python3` for JSON parsing.
`tests/structure.test.sh <root>` checks any plugin tree, which is how the fixtures under `tests/fixtures/`
prove each failure case.
