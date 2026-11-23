export type Chip = '⬜' | '🟡' | '🟢' | '🔴' | '⚪' | '❌'

export type Row = {
  id: string
  ticket: string
  what: string
  chip: Chip
  rollup: string | null
  situation: string
}

export type Decision = { text: string; brief: string | null }

export type Board = {
  name: string
  root: string
  verified: string | null
  criticalPath: string | null
  rows: Row[]
  next: string[]
  decisions: Decision[]
  unread: number
  oldest: string | null
  queue: string[]
}

/** One `scratch/<root>-<short-name>/` folder; `board` is null for an old-shape tracker. */
export type Project = {
  dir: string
  folder: string
  mtimeMs: number
  board: Board | null
}

/** The repo the session is in: its main checkout (null outside git) and whether a config opts it in. */
export type Repo = { main: string | null; isOptedIn: boolean }

declare module 'claude-code' {
  interface PluginState {
    'pw-board': {
      repo: Shaped<Repo>
      projects: Shaped<Project[]>
      selected: string | null
      isBandHidden: boolean
    }
  }
}
