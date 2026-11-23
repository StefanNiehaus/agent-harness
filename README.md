# agent-harness

Opt-in plugins for coding agents. Each plugin is a set of portable [Agent Skills](https://agentskills.io)
and a Claude Code plugin at once, built from one folder. Nothing installs unless you name it.

## Plugins

| Plugin | What it gives you | Needs |
|---|---|---|
| [`project-workflow`](plugins/project-workflow/) | Run an effort of several deliverables and agent threads from one living tracker file: `/pw-open`, `/pw-status`, `/pw-land`, `/pw-brief`. Works with GitHub or Jira tickets. | [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin), `git`, `gh` |

## Install

Clone the repo somewhere it can stay, because the symlink install points into the clone:

```bash
git clone https://github.com/StefanNiehaus/agent-harness.git
cd agent-harness
```

### Any agent that reads Agent Skills (Codex, Gemini CLI, Cursor, others)

```bash
bin/install project-workflow                  # links into ~/.agents/skills
bin/install project-workflow --agent cursor   # or a named agent: claude, codex, gemini, cursor
bin/install project-workflow --dir <path>     # or any skill directory
```

The script only creates links (symlinks, or junctions on Windows), never copies. It never replaces a folder
or a link it did not make, and `bin/install project-workflow --uninstall` removes exactly the links it made.
Run `bin/install` with no arguments to list the plugins.

### Claude Code

Pick **one** of these. Using both gives you two copies of every skill.

- **Symlink** (recommended if you want to keep what the skills learn):

  ```bash
  bin/install project-workflow --agent claude   # links into ~/.claude/skills
  ```

- **Marketplace**:

  ```text
  /plugin marketplace add StefanNiehaus/agent-harness
  /plugin install project-workflow@agent-harness
  ```

Each skill appends lessons to a `learnings.md` in its own folder. With the symlink install that folder is
your clone, so the lessons stay and you can commit them. With the marketplace install it is Claude's plugin
cache, which is replaced when the plugin updates.

### On Windows

Run `bin/install` from Git Bash. There it makes directory junctions instead of symlinks, which need neither
admin rights nor Developer Mode, and it stops with an error rather than copying if a link cannot be made.
`present`, `refused` and `--uninstall` treat the junctions like any other link.

Optional alternatives:

- **Junctions by hand**, from PowerShell in the clone (here for Claude Code's skill folder). `bin/install`
  recognizes these as its own links:

  ```powershell
  Get-ChildItem plugins\project-workflow\skills -Directory | ForEach-Object {
    New-Item -ItemType Junction -Path "$HOME\.claude\skills\$($_.Name)" -Target $_.FullName }
  ```

- **Developer Mode** does not change what `bin/install` makes. Note that a plain `ln -s` in Git Bash without
  it quietly copies the folder, so your edits and lessons never reach the clone.

Do not install from WSL for a Windows agent: links made inside WSL may not resolve for Windows programs. To
run the tests on Windows, see [`AGENTS.md`](AGENTS.md).

## After installing

Each plugin's README says how to switch it on for a repo. `project-workflow` needs a small config file per
repo: see [its README](plugins/project-workflow/README.md).

## License

[Apache License 2.0](LICENSE).

## Contributing

`tests/run` must pass. It checks that every skill is portable (open-spec frontmatter, no agent-specific tool
names), that the skills stay tracker-neutral, and that no personal or employer values are in the repo.
[`AGENTS.md`](AGENTS.md) has the rules.
