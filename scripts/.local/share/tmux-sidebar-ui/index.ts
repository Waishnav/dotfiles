import { $ } from "bun"
import {
  BoxRenderable,
  CliRenderer,
  MouseButton,
  ScrollBoxRenderable,
  TextAttributes,
  TextRenderable,
  createCliRenderer,
} from "@opentui/core"

type Session = {
  name: string
  windows: number
}

type WindowItem = {
  index: number
  name: string
  active: boolean
}

type SidebarRow =
  | { kind: "session"; session: Session }
  | { kind: "window"; session: string; window: WindowItem }

type RowView = {
  key: string
  label: string
  fg: string
  bg: string
  attributes: number
}

const COLORS = {
  bg: "#1a1a1a",
  panel: "#202020",
  selected: "#3c3c3c",
  header: "#00ff99",
  separator: "#505050",
  active: "#5eacd3",
  inactive: "#a0a0a0",
  window: "#c4b48f",
  windowDim: "#7c7464",
}

const REFRESH_MS = 1200

class SidebarApp {
  private renderer: CliRenderer
  private root: BoxRenderable
  private header: TextRenderable
  private footer: TextRenderable
  private list: ScrollBoxRenderable
  private rows: SidebarRow[] = []
  private sessions: Session[] = []
  private windows = new Map<string, WindowItem[]>()
  private expanded = new Set<string>()
  private selectedIndex = 0
  private activeSession = ""
  private refreshTimer: Timer | undefined
  private previousRowViews: RowView[] = []
  private stateFingerprint = ""

  constructor(renderer: CliRenderer) {
    this.renderer = renderer

    this.root = new BoxRenderable(renderer, {
      id: "sidebar-root",
      width: "100%",
      height: "100%",
      flexDirection: "column",
      backgroundColor: COLORS.bg,
    })

    this.header = new TextRenderable(renderer, {
      id: "sidebar-header",
      content: "  Sessions",
      fg: COLORS.header,
      bg: COLORS.bg,
      attributes: TextAttributes.BOLD,
      height: 1,
      selectable: false,
    })

    this.list = new ScrollBoxRenderable(renderer, {
      id: "sidebar-list",
      width: "100%",
      flexGrow: 1,
      scrollY: true,
      scrollX: false,
      viewportCulling: true,
      rootOptions: {
        backgroundColor: COLORS.bg,
      },
      wrapperOptions: {
        backgroundColor: COLORS.bg,
      },
      viewportOptions: {
        backgroundColor: COLORS.bg,
      },
      contentOptions: {
        backgroundColor: COLORS.bg,
        flexDirection: "column",
      },
      verticalScrollbarOptions: {
        trackOptions: {
          backgroundColor: COLORS.bg,
          foregroundColor: COLORS.separator,
        },
      },
    })

    this.footer = new TextRenderable(renderer, {
      id: "sidebar-footer",
      content: " j/k move  alt+j/k sessions  l expand  w expand-all  enter switch  esc hide",
      fg: COLORS.separator,
      bg: COLORS.bg,
      height: 1,
      selectable: false,
      truncate: true,
    })

    const separator = new TextRenderable(renderer, {
      id: "sidebar-separator",
      content: "-".repeat(Math.max(10, renderer.width || 20)),
      fg: COLORS.separator,
      bg: COLORS.bg,
      height: 1,
      selectable: false,
      truncate: true,
    })

    this.root.add(this.header)
    this.root.add(separator)
    this.root.add(this.list)
    this.root.add(this.footer)
    this.renderer.root.add(this.root)
  }

  async start() {
    this.bindKeys()
    this.renderer.on("resize", () => {
      const sep = this.root.findDescendantById("sidebar-separator") as TextRenderable | undefined
      if (sep) sep.content = "-".repeat(Math.max(10, this.renderer.width || 20))
    })
    await this.refresh()
    this.refreshTimer = setInterval(() => {
      void this.refresh()
    }, REFRESH_MS)
  }

  destroy() {
    if (this.refreshTimer) clearInterval(this.refreshTimer)
    this.renderer.destroy()
  }

  private bindKeys() {
    this.renderer.keyInput.on("keypress", (key) => {
      if (key.meta && key.name === "j") {
        this.jumpSession(1)
        return
      }
      if (key.meta && key.name === "k") {
        this.jumpSession(-1)
        return
      }
      if (key.name === "down" || key.name === "j") {
        this.moveSelection(1)
        return
      }
      if (key.name === "up" || key.name === "k") {
        this.moveSelection(-1)
        return
      }
      if (key.name === "right" || key.name === "l" || key.name === "tab") {
        this.expandSelected()
        return
      }
      if (key.name === "left" || key.name === "h") {
        this.collapseSelected()
        return
      }
      if (key.name === "return") {
        void this.activateSelected()
        return
      }
      if (key.name === "w") {
        void this.expandAllSessions()
        return
      }
      if (key.name === "escape") {
        void this.hideSidebar()
        return
      }
      if (key.name === "g") {
        this.selectedIndex = 0
        this.renderRows()
        return
      }
      if (key.shift && key.name === "g") {
        this.selectedIndex = Math.max(0, this.rows.length - 1)
        this.renderRows()
      }
    })
  }

  private async refresh() {
    this.sessions = await this.fetchSessions()
    this.activeSession = await this.fetchActiveSession()

    for (const session of this.sessions) {
      if (this.expanded.has(session.name)) {
        this.windows.set(session.name, await this.fetchWindows(session.name))
      }
    }

    this.buildRows()
    const nextFingerprint = JSON.stringify({
      rows: this.rows,
      activeSession: this.activeSession,
      selectedIndex: this.selectedIndex,
      expanded: [...this.expanded].sort(),
    })
    if (nextFingerprint === this.stateFingerprint) {
      return
    }
    this.stateFingerprint = nextFingerprint
    this.renderRows()
  }

  private async fetchSessions(): Promise<Session[]> {
    const out = await $`tmux list-sessions -F '#{session_name}|#{session_windows}'`.quiet().nothrow().text()
    return out
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean)
      .map((line) => {
        const [name, windows] = line.split("|")
        return { name, windows: Number(windows || 0) }
      })
  }

  private async fetchWindows(session: string): Promise<WindowItem[]> {
    const out = await $`tmux list-windows -t ${session} -F '#{window_index}|#{window_name}|#{window_active}'`.quiet().nothrow().text()
    return out
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean)
      .map((line) => {
        const [index, name, active] = line.split("|")
        return {
          index: Number(index || 0),
          name: name || "window",
          active: active === "1",
        }
      })
  }

  private async fetchActiveSession(): Promise<string> {
    const out = await $`tmux list-clients -F '#{client_name}|#{session_name}|#{client_activity}'`.quiet().nothrow().text()
    const line = out
      .split("\n")
      .map((value) => value.trim())
      .filter(Boolean)
      .filter((value) => !value.includes("sidebar-tui"))
      .sort((a, b) => {
        const aActivity = Number(a.split("|")[2] || 0)
        const bActivity = Number(b.split("|")[2] || 0)
        return bActivity - aActivity
      })[0]

    return line ? line.split("|")[1] || "" : ""
  }

  private buildRows() {
    const nextRows: SidebarRow[] = []
    for (const session of this.sessions) {
      nextRows.push({ kind: "session", session })
      if (this.expanded.has(session.name)) {
        for (const window of this.windows.get(session.name) || []) {
          nextRows.push({ kind: "window", session: session.name, window })
        }
      }
    }
    this.rows = nextRows
    if (this.selectedIndex >= this.rows.length) {
      this.selectedIndex = Math.max(0, this.rows.length - 1)
    }
  }

  private renderRows() {
    const nextViews = this.rows.map((row, index) => this.toRowView(row, index))

    const structureChanged =
      nextViews.length !== this.previousRowViews.length ||
      nextViews.some((view, index) => this.previousRowViews[index]?.key !== view.key)

    if (structureChanged) {
      for (const child of this.list.getChildren()) {
        this.list.remove(child.id)
      }
      nextViews.forEach((_, index) => {
        this.list.add(this.createRow(this.rows[index]!, index))
      })
    }

    nextViews.forEach((view, index) => {
      const prev = this.previousRowViews[index]
      if (
        structureChanged ||
        !prev ||
        prev.label !== view.label ||
        prev.fg !== view.fg ||
        prev.bg !== view.bg ||
        prev.attributes !== view.attributes
      ) {
        this.updateExistingRow(index, view)
      }
    })

    this.previousRowViews = nextViews

    this.ensureSelectionVisible()
    this.renderer.requestRender()
  }

  private toRowView(row: SidebarRow, index: number): RowView {
    const selected = index === this.selectedIndex

    if (row.kind === "session") {
      const isExpanded = this.expanded.has(row.session.name)
      const arrow = isExpanded ? "▼" : "▸"
      return {
        key: `session:${row.session.name}`,
        label: ` ${arrow} ${row.session.name} (${row.session.windows}w)`,
        fg: row.session.name === this.activeSession ? COLORS.active : COLORS.inactive,
        bg: selected ? COLORS.selected : COLORS.bg,
        attributes: row.session.name === this.activeSession ? TextAttributes.BOLD : TextAttributes.NONE,
      }
    }

    return {
      key: `window:${row.session}:${row.window.index}`,
      label: `      ${row.window.index}: ${row.window.name}`,
      fg: row.window.active ? COLORS.window : COLORS.windowDim,
      bg: selected ? COLORS.selected : COLORS.bg,
      attributes: TextAttributes.NONE,
    }
  }

  private updateExistingRow(index: number, view: RowView) {
    const box = this.list.findDescendantById(`row-${index}`) as BoxRenderable | undefined
    const text = this.list.findDescendantById(`row-text-${index}`) as TextRenderable | undefined
    if (!box || !text) return
    box.backgroundColor = view.bg
    text.bg = view.bg
    text.fg = view.fg
    text.attributes = view.attributes
    text.content = view.label
  }

  private createRow(row: SidebarRow, index: number) {
    const view = this.toRowView(row, index)
    const box = new BoxRenderable(this.renderer, {
      id: `row-${index}`,
      width: "100%",
      height: 1,
      backgroundColor: view.bg,
      focusable: true,
      onMouseDown: (event) => {
        if (event.button !== MouseButton.LEFT) return
        this.selectedIndex = index
        void this.activateSelected()
      },
    })

    const text = new TextRenderable(this.renderer, {
      id: `row-text-${index}`,
      width: "100%",
      height: 1,
      bg: view.bg,
      fg: view.fg,
      attributes: view.attributes,
      truncate: true,
      selectable: false,
    })
    text.content = view.label

    box.add(text)
    return box
  }

  private moveSelection(delta: number) {
    if (this.rows.length === 0) return
    const next = Math.max(0, Math.min(this.rows.length - 1, this.selectedIndex + delta))
    if (next === this.selectedIndex) return
    this.selectedIndex = next
    this.stateFingerprint = ""
    this.renderRows()
  }

  private jumpSession(delta: number) {
    if (this.rows.length === 0) return

    let index = this.selectedIndex
    while (true) {
      index += delta
      if (index < 0 || index >= this.rows.length) return
      const row = this.rows[index]
      if (row?.kind === "session") {
        this.selectedIndex = index
        this.stateFingerprint = ""
        this.renderRows()
        return
      }
    }
  }

  private async expandAllSessions() {
    let changed = false
    for (const session of this.sessions) {
      if (!this.expanded.has(session.name)) {
        this.expanded.add(session.name)
        this.windows.set(session.name, await this.fetchWindows(session.name))
        changed = true
      }
    }

    if (!changed) return

    this.buildRows()
    this.stateFingerprint = ""
    this.renderRows()
  }

  private async expandSelected() {
    const row = this.rows[this.selectedIndex]
    if (!row || row.kind !== "session") return
    if (!this.expanded.has(row.session.name)) {
      this.expanded.add(row.session.name)
      this.windows.set(row.session.name, await this.fetchWindows(row.session.name))
      this.buildRows()
      this.stateFingerprint = ""
      this.renderRows()
    }
  }

  private collapseSelected() {
    const row = this.rows[this.selectedIndex]
    if (!row) return

    if (row.kind === "session") {
      if (this.expanded.has(row.session.name)) {
        this.expanded.delete(row.session.name)
        this.buildRows()
        this.stateFingerprint = ""
        this.renderRows()
      }
      return
    }

    this.expanded.delete(row.session)
    this.buildRows()
    const parentIndex = this.rows.findIndex(
      (item) => item.kind === "session" && item.session.name === row.session,
    )
    if (parentIndex >= 0) this.selectedIndex = parentIndex
    this.stateFingerprint = ""
    this.renderRows()
  }

  private async activateSelected() {
    const row = this.rows[this.selectedIndex]
    if (!row) return

    if (row.kind === "session") {
      await this.switchTmuxTarget(row.session.name)
      return
    }

    await this.switchTmuxTarget(`${row.session}:${row.window.index}`)
  }

  private async switchTmuxTarget(target: string) {
    const tty = await this.fetchPrimaryClientTty()
    if (tty) {
      await $`tmux switch-client -c ${tty} -t ${target}`.quiet().nothrow()
    } else {
      await $`tmux switch-client -t ${target}`.quiet().nothrow()
    }
    await this.hideSidebar()
  }

  private async fetchPrimaryClientTty(): Promise<string> {
    const out = await $`tmux list-clients -F '#{client_tty}|#{client_name}'`.quiet().nothrow().text()
    const line = out
      .split("\n")
      .map((value) => value.trim())
      .filter(Boolean)
      .find((value) => !value.includes("sidebar-tui"))
    return line ? line.split("|")[0] || "" : ""
  }

  private ensureSelectionVisible() {
    if (this.selectedIndex < this.list.scrollTop) {
      this.list.scrollTop = this.selectedIndex
      return
    }
    const viewportHeight = Math.max(1, this.list.height)
    const bottomVisible = this.list.scrollTop + viewportHeight - 1
    if (this.selectedIndex > bottomVisible) {
      this.list.scrollTop = Math.max(0, this.selectedIndex - viewportHeight + 1)
    }
  }

  private async hideSidebar() {
    await $`/home/waishnav/.local/bin/tmux-sidebar-toggle hide`.quiet().nothrow()
  }
}

const renderer = await createCliRenderer({
  exitOnCtrlC: true,
  useMouse: true,
  autoFocus: true,
  enableMouseMovement: false,
  useAlternateScreen: true,
  backgroundColor: COLORS.bg,
})

const app = new SidebarApp(renderer)
await app.start()

process.on("uncaughtException", (error) => {
  console.error(error)
  app.destroy()
  process.exit(1)
})

process.on("unhandledRejection", (error) => {
  console.error(error)
  app.destroy()
  process.exit(1)
})
