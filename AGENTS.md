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
- A setup trap costs a contributor time: write the fix where the next person will look (Tests below, or the
  README's Install), so nobody solves it twice.

## Tests

`tests/run` executes every `tests/*.test.sh`. The tests are plain bash and need `python3` for JSON parsing.
`tests/structure.test.sh <root>` checks any plugin tree, which is how the fixtures under `tests/fixtures/`
prove each failure case.

### On Windows

Run the tests in WSL, not Git Bash. Git Bash fails them for reasons that have nothing to do with the repo: its
`ln -s` copies instead of linking unless Developer Mode is on, `python3` is often the Microsoft Store stub,
and its `grep` 3.0 aborts on `grep -iF` without a UTF-8 locale. A WSL distro (Ubuntu) has none of these, and
it can test the Windows clone in place:

```powershell
wsl -d Ubuntu --cd C:\path\to\agent-harness -- bash tests/run
```

- **Line endings.** `.gitattributes` keeps every text file LF whatever `core.autocrlf` says. A clone made
  before that file existed may still hold CRLF copies: re-checkout with `git rm -r --cached . && git reset --hard`.
- **Worktrees.** Git for Windows writes worktree links as `C:/...` paths, which WSL's git cannot follow. Once
  per clone, run `git config worktree.useRelativePaths true`, then `git worktree repair --relative-paths`
  (Git 2.48 or newer).
- Commit and push from Windows; WSL only needs to run the tests.
