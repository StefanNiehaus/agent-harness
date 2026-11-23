import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Board, Project, Repo } from '../types'
import { CHIP_LOOK, parseTracker } from './tracker'

const PANE = 'pw-board'
const TITLE = 'Project board'
const POLL_MS = 4000
const BRIEF_RE = /[\\/]scratch[\\/]([^\\/]+)[\\/]briefs[\\/]([^\\/]+\.html)$/

// Change a tag when that value's fields change: it declines what an earlier
// version stored, which outlives a reload.
const projects = atom({ plugin: 'pw-board', key: 'projects' } as const, [], {
  shape: 'projects-1',
})
const repo = atom(
  { plugin: 'pw-board', key: 'repo' } as const,
  { main: null, isOptedIn: false },
  { shape: 'repo-1' },
)
const selected = atom({ plugin: 'pw-board', key: 'selected' } as const, null)
const isBandHidden = atom({ plugin: 'pw-board', key: 'isBandHidden' } as const, false)

const join = (...parts: string[]) => parts.join('/').replace(/[\\/]+/g, '/')

/** The repo's main checkout, where every project folder lives; null outside git. */
const mainCheckout = async ($: EngineInterface): Promise<string | null> => {
  const root = await $.session.root()
  const run = await $.process
    .run(['git', 'worktree', 'list', '--porcelain'], { cwd: root })
    .catch(() => null)
  if (!run || run.exitCode !== 0) return null
  return /^worktree (.+)$/m.exec(run.stdout)?.[1]?.trim() ?? null
}

const readOr = async ($: EngineInterface, path: string, fallback: string) =>
  $.fs.read(path).then(t => (typeof t === 'string' ? t : fallback)).catch(() => fallback)

/** Re-reads every project folder whose tracker.md changed since the last look. */
const refresh = async ($: EngineInterface) => {
  const main = await mainCheckout($)
  const configs = main
    ? await Promise.all(
        ['.project-workflow.yml', '.project-workflow.local.yml'].map(name => readOr($, join(main, name), '')),
      )
    : []
  const isOptedIn = configs.some(text => /^tracker:\s*\S/m.test(text))
  const before = await read($, repo)
  if (before.main !== main || before.isOptedIn !== isOptedIn) {
    const next: Repo = { main, isOptedIn }
    await update($, repo, () => next)
  }
  const scratch = main ? join(main, 'scratch') : null
  const entries = scratch ? await $.fs.list(scratch).catch(() => []) : []
  const known = new Map((await read($, projects)).map(p => [p.dir, p]))
  const found: Project[] = []
  for (const entry of entries) {
    if (entry.kind !== 'dir' || scratch === null) continue
    const dir = join(scratch, entry.name)
    const file = join(dir, 'tracker.md')
    const stat = await $.fs.stat(file).catch(() => null)
    if (!stat) continue
    const before = known.get(dir)
    if (before && before.mtimeMs === stat.mtimeMs) {
      found.push(before)
      continue
    }
    const text = await readOr($, file, '')
    const decomposition = await readOr($, join(dir, 'decomposition.md'), '')
    found.push({ dir, folder: entry.name, mtimeMs: stat.mtimeMs, board: parseTracker(text, decomposition) })
  }
  const isSame =
    found.length === known.size && found.every(p => known.get(p.dir)?.mtimeMs === p.mtimeMs)
  if (!isSame) await update($, projects, () => found)
  const pick = await read($, selected)
  if (found.length > 0 && !found.some(p => p.dir === pick)) {
    const newest = [...found].sort((a, b) => b.mtimeMs - a.mtimeMs)[0]
    if (newest) await update($, selected, () => newest.dir)
  }
  if (found.length === 0 && pick !== null) await update($, selected, () => null)
}

const current = async ($: EngineInterface): Promise<Project | null> => {
  const list = await read($, projects)
  const pick = await read($, selected)
  return list.find(p => p.dir === pick) ?? list[0] ?? null
}

/** Opens a file with the operating system's default app. */
const openFile = async ($: EngineInterface, path: string) => {
  const isWindows = /^[A-Za-z]:/.test(path)
  if (isWindows) {
    await $.process.run(['cmd', '/c', 'start', '', path.replace(/\//g, '\\')]).catch(() => null)
    return
  }
  const uname = await $.process.run(['uname']).catch(() => null)
  const opener = uname?.stdout.trim() === 'Darwin' ? 'open' : 'xdg-open'
  await $.process.run([opener, path]).catch(() => null)
}

const ago = (now: number, then: number): string => {
  const minutes = Math.round((now - then) / 60000)
  if (minutes < 1) return 'just now'
  if (minutes < 60) return `${minutes} min ago`
  const hours = Math.round(minutes / 60)
  return hours < 48 ? `${hours} h ago` : `${Math.round(hours / 24)} days ago`
}

const projectLabel = (p: Project) => p.board?.root || p.folder

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    await $.command.register({ name: 'pw-board', description: 'Show the project board pane' })
    await refresh($)
    $.clock.every(POLL_MS, () => void refresh($))
    return result
  })

  on('command.run', { command: 'pw-board' }, async $ => {
    await refresh($)
    await update($, isBandHidden, () => false)
    await $.ui.open({ id: PANE, title: TITLE })
    return { text: 'Project board opened.' }
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    await refresh($)
    return result
  })

  // A: the board pane.
  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button, Select, Code } = $.ui.resolve(e)
    const list = await read($, projects)
    const project = await current($)

    if (!project) {
      const { main, isOptedIn } = await read($, repo)
      if (main === null) {
        return (
          <Box flexDirection="column" gap={1}>
            <Text bold>No repo here</Text>
            <Text dimColor>Open a session inside a git repo to see its projects.</Text>
          </Box>
        )
      }
      if (!isOptedIn) {
        return (
          <Box flexDirection="column" gap={1}>
            <Text bold>Set this repo up first</Text>
            <Text dimColor>
              Commit a .project-workflow.yml at the repo root naming your ticket tracker, for example:
            </Text>
            <Code language="yaml" source={'tracker: github\ndone: owner\ngithub:\n  repo: your-org/your-repo'} />
            <Text dimColor>Jira works too: see the project-workflow README. Then open a project here.</Text>
          </Box>
        )
      }
      return (
        <Box flexDirection="column" gap={1}>
          <Box flexDirection="column">
            <Text bold>Start your first project</Text>
            <Text dimColor>
              A project groups several deliverables under one root ticket, tracked in one file.
            </Text>
          </Box>
          <Box flexDirection="column">
            <Text>For example, for GitHub issue 12:</Text>
            <Code source="/pw-open GH-12" />
            <Text dimColor>{'This creates scratch/GH-12-<short-name>/ with its tracker, and the board shows it here.'}</Text>
          </Box>
          <Box flexDirection="row">
            <Button
              key="start"
              label="Start a project"
              variant="primary"
              onPress={() => void $.prompt.fill({ text: '/pw-open ' })}
            />
          </Box>
          <Box flexDirection="column">
            <Text bold>Then</Text>
            <Text dimColor>1. Check where it stands with Reconcile, here or /pw-status</Text>
            <Text dimColor>2. Start each deliverable in a fresh session with its start line</Text>
            <Text dimColor>3. Ask for decisions with /pw-brief; they show under Needs you</Text>
            <Text dimColor>4. Land merged work with /pw-land, and close the project when done</Text>
          </Box>
        </Box>
      )
    }

    const picker =
      list.length > 1 ? (
        <Select
          key="project"
          value={project.dir}
          options={list.map(p => ({ value: p.dir, label: projectLabel(p) }))}
          onSelect={value => update($, selected, () => value)}
        />
      ) : null

    const board = project.board
    if (!board) {
      return (
        <Box flexDirection="column" gap={1}>
          {picker}
          <Text bold>{project.folder}</Text>
          <Text color="warning">Old-shape tracker, so there's no board.</Text>
          <Text dimColor>Close it with /pw-land {project.folder} close.</Text>
        </Box>
      )
    }

    const now = await $.clock.now()
    const root = board.root || project.folder

    return (
      <Box flexDirection="column" gap={1}>
        {picker}
        <Box flexDirection="column">
          <Text bold>
            {root} · {board.name}
          </Text>
          <Text dimColor>tracker.md · edited {ago(now, project.mtimeMs)}</Text>
        </Box>

        {board.decisions.length > 0 && (
          <Box flexDirection="column" borderStyle="round" borderColor="warning" paddingX={1}>
            <Text color="warning" bold>
              Needs you
            </Text>
            {board.decisions.map((d, i) => (
              <Box flexDirection="row" gap={1} alignItems="center">
                <Text color="warning">{d.text}</Text>
                {d.brief && (
                  <Button
                    key={`brief-${i}`}
                    label="Open brief"
                    variant="secondary"
                    onPress={() => openFile($, join(project.dir, d.brief ?? ''))}
                  />
                )}
              </Box>
            ))}
          </Box>
        )}

        <Box flexDirection="column">
          {board.rows.length === 0 && <Text dimColor>No deliverable has started yet.</Text>}
          {board.rows.map(row => (
            <Box flexDirection="row" gap={1}>
              <Text bold>{row.id}</Text>
              <Box flexDirection="column" flexGrow={1} flexShrink={1}>
                <Text>{row.what}</Text>
                {row.situation !== '' && <Text dimColor>{row.situation}</Text>}
              </Box>
              <Text color={CHIP_LOOK[row.chip].color}>
                {row.chip} {row.rollup ?? CHIP_LOOK[row.chip].word}
              </Text>
            </Box>
          ))}
        </Box>

        <Box flexDirection="column">
          {board.criticalPath && <Text>Critical path: {board.criticalPath}</Text>}
          {board.next.length > 0 && <Text>Next: {board.next.slice(0, 2).join(' · ')}</Text>}
          <Text>
            Queue: {board.queue.length} waiting
            {board.queue.length > 0 ? ` · next: ${board.queue.slice(0, 2).join(', ')}` : ''}
          </Text>
          {board.unread > 0 && (
            <Text>
              Messages: {board.unread} unread{board.oldest ? `, oldest ${board.oldest}` : ''}
            </Text>
          )}
          {board.verified && <Text dimColor>Last reconciled {board.verified}</Text>}
        </Box>

        <Box flexDirection="column" gap={1}>
          <Box flexDirection="row" gap={1} alignItems="center">
            <Button
              key="reconcile"
              label="Reconcile"
              variant="primary"
              onPress={() => void $.prompt.submit({ text: `/pw-status ${root}` })}
            />
            <Text dimColor>Check against live tickets, PRs and worktrees. Read-only.</Text>
          </Box>
          <Box flexDirection="row" gap={1} alignItems="center">
            <Box borderStyle="single" borderColor="inactive" padding={0}>
              <Button
                key="sweep"
                label="Sweep"
                variant="secondary"
                onPress={() => void $.prompt.submit({ text: `/pw-status ${root} sweep` })}
              />
            </Box>
            <Text dimColor>Reconcile, then fix tracker drift and stale tickets. Can write.</Text>
          </Box>
        </Box>
      </Box>
    )
  })

  // C: the band above the prompt.
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const project = await current($)
    if (e.props.hasSurvey || !project || (await read($, isBandHidden))) return next(e)
    const { Box, Text, Button } = $.ui.resolve(e)
    const board: Board | null = project.board

    return (
      <Box flexDirection="row" gap={1} alignItems="center" flexWrap="wrap">
        <Text bold>{projectLabel(project)}</Text>
        {board ? (
          board.rows.map(row => (
            <Text color={CHIP_LOOK[row.chip].color}>
              {row.chip}
              {row.id}
              {row.rollup ? ` ${row.rollup}` : ''}
            </Text>
          ))
        ) : (
          <Text color="warning">old-shape tracker</Text>
        )}
        {board && board.decisions.length > 0 && (
          <Text color="warning">
            · {board.decisions.length} decision{board.decisions.length > 1 ? 's' : ''}
          </Text>
        )}
        {board && board.unread > 0 && <Text dimColor>· {board.unread} unread</Text>}
        <Button key="board" label="Board" variant="secondary" onPress={() => void $.ui.open({ id: PANE, title: TITLE })} />
        <Button key="hide" label="Hide" variant="secondary" onPress={() => update($, isBandHidden, () => true)} />
      </Box>
    )
  })

  // C: a card under the tool call that writes a brief.
  on('ui.render', { component: 'ToolUse' }, async ($, e, next) => {
    const input = e.props.input as { file_path?: unknown } | undefined
    const path = typeof input?.file_path === 'string' ? input.file_path : ''
    const match = BRIEF_RE.exec(path)
    if (e.props.tool !== 'Write' || !match || e.props.isRunning || e.props.isErrored) return next(e)

    const { Box, Text, Button } = $.ui.resolve(e)
    const row = await next(e)
    const html = await readOr($, path, '')
    const title = /<title>([^<]*)<\/title>/i.exec(html)?.[1]?.trim() || match[2]

    return (
      <Box flexDirection="column" borderStyle="round" borderDimColor paddingX={1}>
        {row}
        <Box flexDirection="row" gap={1} alignItems="center">
          <Box flexDirection="column" flexGrow={1} flexShrink={1}>
            <Text bold>{title}</Text>
            <Text dimColor>
              Brief for {match[1]} · briefs/{match[2]}
            </Text>
          </Box>
          <Button key="open-brief" label="Open" variant="secondary" onPress={() => openFile($, path)} />
        </Box>
      </Box>
    )
  })
}
