import { expect, test } from 'claude-code/testing'

import { parseTracker } from './tracker'

// A tracker filled in from the plugin's templates/tracker.md.
const TRACKER = `# Offline sync — Project Tracker (GH-12)

<!-- TEMPLATE guidance that /pw-open leaves behind | D | not | a | row | -->

> **Living, gitignored tracker.** Created 2026-11-01. Never commit it.
> **Shape: project-workflow/v1.** Procedures: \`/pw-land <project> <task-id>\`.

## Status board

Tracker verified 2026-11-22 (9-key reconcile — clean). **Critical path:** D2 → D3.

| D | Ticket | Deliverable (plain English) | Entry | Exit | Tracker | State |
|---|--------|-----------------------------|-------|------|---------|-------|
| D1 | GH-13 | Local cache survives a restart | \`/ce-plan\` | \`—\` | Done | 🟢 — #41 |
| D2 | GH-14 | Conflicts resolve **without** data loss | \`/ce-plan\` | \`—\` | In Progress | 🟡 2/3 — PR behind base |
| D3 | GH-15 | Sync status shown in the app | \`/ce-plan\` | \`—\` | To Do | 🔴 — gated on D2 |

## Messages

- 2026-11-21 D2→D3: schema settled → docs/x.md
- ~~2026-11-18 D1→D2: cache API ready~~
- 2026-11-20 D3→D2: need the conflict event name

## Next actions

1. **D2 — rebase the PR onto main.**
2. **retry-ui — start from the Queue.**

## Open decisions

- **Merge strategy for D2 — open (owner, gates \`D2\`):** last-write-wins or field merge → \`briefs/d2-merge-strategy.html\`.

---

## Per-deliverable detail

### D1 — GH-13 — cache
`

const DECOMPOSITION = `## Queue (proposed order; no numbers)

<!-- - \`<handle>\` — template shape -->
**Deliverables:**
- \`retry-ui\` — background retry with backoff · fence: none.
- \`docs\` — user docs.

## Not in this project
`

test('a v1 tracker reads into the board', () => {
  const board = parseTracker(TRACKER, DECOMPOSITION)
  expect(board?.name).toBe('Offline sync')
  expect(board?.root).toBe('GH-12')
  expect(board?.verified).toBe('2026-11-22')
  expect(board?.criticalPath).toBe('D2 → D3')
  expect(board?.rows.map(r => r.id).join(',')).toBe('D1,D2,D3')
  expect(board?.rows[1]?.what).toBe('Conflicts resolve without data loss')
  expect(board?.rows[1]?.chip).toBe('🟡')
  expect(board?.rows[1]?.rollup).toBe('2/3')
  expect(board?.rows[1]?.situation).toBe('PR behind base')
  expect(board?.rows[2]?.chip).toBe('🔴')
  expect(board?.rows[0]?.rollup).toBe(null)
})

test('messages, next actions, decisions and the queue', () => {
  const board = parseTracker(TRACKER, DECOMPOSITION)
  expect(board?.unread).toBe(2)
  expect(board?.oldest).toBe('2026-11-20')
  expect(board?.next.join(' | ')).toBe('D2 — rebase the PR onto main | retry-ui — start from the Queue')
  expect(board?.decisions.length).toBe(1)
  expect(board?.decisions[0]?.text).toBe('Merge strategy for D2: last-write-wins or field merge')
  expect(board?.decisions[0]?.brief).toBe('briefs/d2-merge-strategy.html')
  expect(board?.queue.join(',')).toBe('retry-ui,docs')
})

test('a tracker without the v1 shape line gets no board', () => {
  expect(parseTracker(TRACKER.replace('Shape: project-workflow/v1', 'Shape: old'))).toBe(null)
})

test('an empty decisions list and a fresh board read cleanly', () => {
  const fresh = TRACKER.replace(/\| D1[\s\S]*?\n\n/, '\n').replace(
    /- \*\*Merge strategy[^\n]*/,
    '- _(none open)_',
  )
  const board = parseTracker(fresh)
  expect(board?.decisions.length).toBe(0)
  expect(board?.queue.length).toBe(0)
})
