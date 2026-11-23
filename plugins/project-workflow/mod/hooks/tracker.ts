// Reads a project-workflow/v1 tracker.md (and its decomposition.md) into the
// shape the pane, band and tests draw from. Pure text in, plain data out: no
// engine calls, so `claude plugin test` can feed it the plugin's own template.

import type { Board, Chip, Decision, Row } from '../types'

const CHIPS: readonly Chip[] = ['⬜', '🟡', '🟢', '🔴', '⚪', '❌']
const CHIP_RE = /(⬜|🟡|🟢|🔴|⚪|❌)/u
const SHAPE_RE = /Shape:\s*project-workflow\/v1\b/

/** Drops the markdown marks a one-line cell or list item carries. */
export const plain = (text: string): string =>
  text
    .replace(/\*\*|__/g, '')
    .replace(/`/g, '')
    .replace(/^_\((.*)\)_$/, '$1')
    .replace(/\s+/g, ' ')
    .trim()

/** The lines under `## <heading…>`, up to the next `## ` heading or a `---` rule. */
export const section = (text: string, heading: string): string[] => {
  const lines = text.split(/\r?\n/)
  const start = lines.findIndex(line => line.startsWith(`## ${heading}`))
  if (start < 0) return []
  const out: string[] = []
  for (const line of lines.slice(start + 1)) {
    if (line.startsWith('## ') || line.trim() === '---') break
    out.push(line)
  }
  return out
}

/** Drops `<!-- … -->` blocks, which hold the template's guidance and shapes. */
const uncomment = (text: string): string => text.replace(/<!--[\s\S]*?-->/g, '')

const cells = (line: string): string[] =>
  line.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map(c => c.trim())

const parseState = (cell: string): Pick<Row, 'chip' | 'rollup' | 'situation'> => {
  const found = CHIP_RE.exec(cell)
  const chip = (found?.[1] as Chip | undefined) ?? '⬜'
  const token = found?.[1] ?? ''
  const rest = found ? cell.slice(found.index + token.length) : cell
  const rollup = /^\s*(\d+\/\d+)/.exec(rest)?.[1] ?? null
  const dash = rest.indexOf('—')
  const situation = dash >= 0 ? plain(rest.slice(dash + 1)) : ''
  return { chip, rollup, situation }
}

const parseRows = (text: string): Row[] => {
  const lines = section(text, 'Status board')
  const head = lines.findIndex(line => /^\|\s*D\s*\|/.test(line))
  if (head < 0) return []
  const names = cells(lines[head] ?? '').map(n => n.toLowerCase())
  const at = (prefix: string) => names.findIndex(n => n.startsWith(prefix))
  const iD = at('d')
  const iTicket = at('ticket')
  const iWhat = at('deliverable')
  const iState = at('state')
  const rows: Row[] = []
  for (const line of lines.slice(head + 2)) {
    if (!line.trim().startsWith('|')) break
    const c = cells(line)
    rows.push({
      id: plain(c[iD] ?? ''),
      ticket: plain(c[iTicket] ?? ''),
      what: plain(c[iWhat] ?? ''),
      ...parseState(c[iState] ?? ''),
    })
  }
  return rows
}

const parseDecisions = (text: string): Decision[] =>
  section(text, 'Open decisions')
    .filter(line => /^- /.test(line) && !/^- ~~/.test(line))
    .filter(line => !/^- _\(none open\)_/.test(line))
    .map(line => {
      const brief = /`(briefs\/[^`]+\.html)`/.exec(line)?.[1] ?? null
      const body = line.slice(2).split(' → ')[0] ?? ''
      const text = plain(body)
        .replace(/\s+—\s+open\s*\([^)]*\)/, '')
        .replace(/[:.]$/, '')
      return { text, brief }
    })

const parseMessages = (text: string): { unread: number; oldest: string | null } => {
  const dates = section(text, 'Messages')
    .filter(line => !/^- ~~/.test(line))
    .map(line => /^- (\d{4}-\d{2}-\d{2})/.exec(line)?.[1])
    .filter((d): d is string => d !== undefined)
    .sort()
  return { unread: dates.length, oldest: dates[0] ?? null }
}

/** The unnumbered handles waiting in decomposition.md's Queue, in order. */
export const parseQueue = (decomposition: string): string[] =>
  section(uncomment(decomposition), 'Queue')
    .map(line => /^- `([^`<>]+)`/.exec(line)?.[1])
    .filter((h): h is string => h !== undefined)

/**
 * The board a v1 tracker holds, or `null` for a file without the
 * `Shape: project-workflow/v1` line (an old-shape tracker, never migrated).
 */
export const parseTracker = (raw: string, decomposition = ''): Board | null => {
  if (!SHAPE_RE.test(raw)) return null
  const text = uncomment(raw)
  const title = /^#\s+(.+?)\s+—\s+Project Tracker\s+\((.+?)\)\s*$/m.exec(text)
  const firstHeading = /^#\s+(.+)$/m.exec(text)?.[1] ?? 'Project'
  const critical = /\*\*Critical path:\*\*\s*(.+?)\.?\s*$/m.exec(text)?.[1]
  return {
    name: plain(title?.[1] ?? firstHeading),
    root: plain(title?.[2] ?? ''),
    verified: /Tracker verified (\d{4}-\d{2}-\d{2})/.exec(text)?.[1] ?? null,
    criticalPath: critical ? plain(critical) : null,
    rows: parseRows(text),
    next: section(text, 'Next actions')
      .map(line => /^\d+\.\s+(.*)$/.exec(line)?.[1])
      .filter((n): n is string => n !== undefined)
      .map(n => plain(n).replace(/\.$/, '')),
    decisions: parseDecisions(text),
    ...parseMessages(text),
    queue: parseQueue(decomposition),
  }
}

/** Plain words and a theme color for each chip. */
export const CHIP_LOOK: Record<Chip, { word: string; color: string }> = {
  '⬜': { word: 'todo', color: 'inactive' },
  '🟡': { word: 'in progress', color: 'warning' },
  '🟢': { word: 'done', color: 'success' },
  '🔴': { word: 'blocked', color: 'error' },
  '⚪': { word: 'folded', color: 'subtle' },
  '❌': { word: 'cancelled', color: 'subtle' },
}

export const isChip = (value: string): value is Chip => (CHIPS as readonly string[]).includes(value)
