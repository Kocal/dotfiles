import { Plugin } from "@opencode/plugin/tui"
import { createEffect, createMemo, createSignal, on, onCleanup, Show } from "solid-js"
import { RGBA } from "@opentui/core"

const frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

function label(directory: string) {
  const trimmed = directory.replace(/\/+$/, "")
  const marker = "/.claude/worktrees/"
  const index = trimmed.indexOf(marker)
  if (index !== -1) return trimmed.slice(index + 1)
  return trimmed.split("/").pop() || directory
}

function duration(milliseconds: number) {
  const minutes = Math.max(0, Math.floor(milliseconds / 60_000))
  const hours = Math.floor(minutes / 60)
  return hours > 0 ? `${hours}h${minutes % 60}m` : `${minutes}m`
}

function StatusLine(props: { context: Plugin.Context; sessionID?: string }) {
  const context = props.context
  const colors = {
    get green() {
      return context.theme.text.feedback.success.base
    },
    get yellow() {
      return context.theme.text.feedback.warning.base
    },
    get red() {
      return context.theme.text.feedback.error.base
    },
    get cyan() {
      return context.theme.text.feedback.info.base
    },
    blue: RGBA.fromIndex(4),
    magenta: RGBA.fromIndex(5),
    get added() {
      return context.theme.diff.text.added
    },
    get removed() {
      return context.theme.diff.text.removed
    },
  }

  const session = createMemo(() => (props.sessionID ? context.data.session.get(props.sessionID) : undefined))
  const location = createMemo(() => session()?.location ?? context.location ?? context.data.location.default())
  const directory = createMemo(() => location().directory)
  const branch = createMemo(() => context.data.location.vcs.info(location())?.branch.current)
  const running = createMemo(() => !!props.sessionID && context.data.session.status(props.sessionID) === "running")
  const models = createMemo(() => {
    const current = session()
    return current ? (context.data.location.model.list(current.location) ?? []) : []
  })

  const model = createMemo(() => {
    const current = session()
    if (!current) return
    const selected = context.ui.model.current()
    const ref = selected ? { providerID: selected.providerID, id: selected.modelID } : current.model
    if (!ref) return
    const info = models().find((item) => item.providerID === ref.providerID && item.id === ref.id)
    return info?.name.replace(/^Claude /, "")
  })

  const usage = createMemo(() => {
    const current = session()
    if (!current) return
    const messages = context.data.session.message.list(current.id)
    const boundary = current.revert?.messageID
    const boundaryIndex = boundary ? messages.findIndex((message) => message.id === boundary) : -1
    if (boundary && boundaryIndex === -1) return
    const end = boundaryIndex === -1 ? messages.length : boundaryIndex
    const compaction = messages.findLastIndex(
      (message, index) => message.type === "compaction" && message.status === "completed" && index < end,
    )
    const last = messages.findLast(
      (message, index) =>
        message.type === "assistant" && message.tokens !== undefined && index > compaction && index < end,
    )
    if (!last || last.type !== "assistant" || !last.tokens) return
    const tokens =
      last.tokens.input + last.tokens.output + last.tokens.reasoning + last.tokens.cache.read + last.tokens.cache.write
    if (tokens <= 0) return
    const limit = models().find(
      (item) => item.providerID === last.model.providerID && item.id === last.model.id,
    )?.limit.context
    return limit ? Math.round((tokens / limit) * 100) : undefined
  })

  const cost = createMemo(() => (props.sessionID ? context.data.session.cost(props.sessionID) : 0))

  const [lines, setLines] = createSignal<{ added: number; removed: number }>()
  let request = 0
  const refresh = () => {
    const id = ++request
    if (!session()) return setLines(undefined)
    context.client.vcs.status({ location: { directory: directory() } }).then(
      (response) => {
        if (id !== request) return
        const files = response?.data
        if (
          !Array.isArray(files) ||
          !files.every((file) => typeof file.additions === "number" && typeof file.deletions === "number")
        )
          return setLines(undefined)
        const added = files.reduce((total, file) => total + file.additions, 0)
        const removed = files.reduce((total, file) => total + file.deletions, 0)
        setLines(added || removed ? { added, removed } : undefined)
      },
      () => {
        if (id === request) setLines(undefined)
      },
    )
  }
  createEffect(on([() => !!session(), directory, running], refresh))
  let pending: ReturnType<typeof setTimeout> | undefined
  const stopWatching = context.data.on("session.tool.success", () => {
    clearTimeout(pending)
    pending = setTimeout(refresh, 300)
  })
  onCleanup(() => {
    stopWatching()
    clearTimeout(pending)
  })

  const [now, setNow] = createSignal(Date.now())
  const clock = setInterval(() => {
    setNow(Date.now())
    refresh()
  }, 60_000)
  onCleanup(() => clearInterval(clock))
  const elapsed = createMemo(() => {
    const created = session()?.time.created
    return created ? duration(now() - created) : undefined
  })

  const [frame, setFrame] = createSignal(0)
  createEffect(() => {
    if (!running()) return
    const spinner = setInterval(() => setFrame((value) => (value + 1) % frames.length), 80)
    onCleanup(() => clearInterval(spinner))
  })

  return (
    <box flexDirection="row" flexGrow={1} flexShrink={1} minWidth={0}>
      <Show when={running()}>
        <text fg={context.theme.text.muted} wrapMode="none" flexShrink={0}>
          {frames[frame()]} esc interrupt{" "}
        </text>
      </Show>
      <text wrapMode="none" truncate flexGrow={1} flexShrink={1} minWidth={0}>
        <span style={{ fg: colors.green, bold: true }}>➜</span>{" "}
        <span style={{ fg: colors.cyan }}>{label(directory())}</span>
        <Show when={branch()}>
          {(name) => (
            <>
              {"  "}
              <span style={{ fg: colors.blue, bold: true }}>git:(</span>
              <span style={{ fg: colors.red }}>{name()}</span>
              <span style={{ fg: colors.blue, bold: true }}>)</span>
            </>
          )}
        </Show>
        <Show when={model()}>
          {(name) => <span style={{ fg: colors.magenta }}> 🤖 {name()}</span>}
        </Show>
        <Show when={usage() !== undefined}>
          <span style={{ fg: usage()! >= 80 ? colors.red : usage()! >= 50 ? colors.yellow : colors.green }}>
            {" "}🧠 {usage()}%
          </span>
        </Show>
        <Show when={cost() > 0}>
          <span style={{ fg: colors.yellow }}> 💰 ${cost().toFixed(4)}</span>
        </Show>
        <Show when={lines()}>
          {(value) => (
            <>
              {" "}
              <span style={{ fg: colors.added }}>+{value().added}</span>
              <span style={{ fg: colors.removed }}>-{value().removed}</span>
            </>
          )}
        </Show>
        <Show when={elapsed()}>
          {(value) => <span style={{ fg: colors.cyan }}> ⏱ {value()}</span>}
        </Show>
      </text>
    </box>
  )
}

export default Plugin.define({
  id: "dotfiles.statusline",
  setup(context) {
    context.ui.slot({
      replace: "prompt.footer.status",
      render: (input) => <StatusLine context={context} sessionID={input.sessionID} />,
    })
  },
})
