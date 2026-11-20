# pw-check learnings

<!-- Append one observation per line:
     ### YYYY-MM-DD
     - Observation (one sentence). Source: <tracker path / ticket / rule>.
     Append only when a class of error recurs or the user flags a miss — not speculatively.
     A lesson about one ticket tracker goes in that tracker's op sheet, not here. -->

### 2026-11-20

- Trackers carry project-level tickets (cross-cutting fixes, a design spike, the root) apart from deliverables — render those as a second table, never as deliverable rows. Source: carried over from the workflow's earlier use.
- In zsh an unquoted `$files` does not word-split, so `git diff <branch> <base> -- $files` silently matches nothing and reads as "identical" — iterate per file (`while read`) for branch-absorption checks, and put `--stat` before `--`. Source: carried over; a false "absorbed" verdict would have flagged an unabsorbed branch for cleanup.
- When a large ticket read is saved to a file instead of shown, extract key, status and resolution from that file rather than reading the tickets again, and check from the file that the last page was reached. Source: carried over.
