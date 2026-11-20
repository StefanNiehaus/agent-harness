# Repo config: `.project-workflow.yml`

<!-- tracker-specific -->

A repo opts in to the project workflow by committing `.project-workflow.yml` at the root of its main checkout.
It is flat YAML, read directly by the agent. Skills always read it from the **main checkout**
(`git worktree list --porcelain`, first entry), never from a `.worktrees/` checkout.

| Key | Values | Default | Meaning |
|---|---|---|---|
| `tracker` | `github`, `jira`, or the name of any sheet in `trackers/` | required | Which op sheet the skills use |
| `done` | `owner`, `agent` | `owner` | Who closes tickets. `owner`: agents advance and comment, never close. `agent`: `/pw-land` and PR bodies may close |
| `archive_root` | a directory path | `<parent of the main checkout>/project-archive` | Where `/pw-land <project> close` moves a closed project, under `<archive_root>/<repo-name>/` |
| `<tracker>:` | a block of that tracker's settings | required | Named after the `tracker` value; its keys are listed in that tracker's op sheet |

## GitHub

```yaml
tracker: github
done: owner
github:
  repo: octo-org/octo-repo      # owner/name of the repo whose issues are the tickets
  account: octocat              # optional: the gh account to act as, when several are logged in
```

## Jira

```yaml
tracker: jira
done: owner
jira:
  site: example.atlassian.net   # the Jira site host
  project: ABC                  # the Jira project that new tickets are created in
  land_status: In Review        # optional: the status agents walk a landed ticket to under done: owner
```

## Per-user overrides

An optional `.project-workflow.local.yml` beside the committed file overrides any key for one user. Keep it out
of git (add it to `.gitignore`). Use it for values that differ per person, such as `archive_root` or
`github.account`.

## Credentials

Neither file ever holds a secret. Each tracker's op sheet says where its credentials come from: the tracker
CLI's own login, or environment variables.
