import { existsSync, readFileSync } from "node:fs"
import { homedir } from "node:os"
import { dirname, join } from "node:path"

const OPEN = "<claude-code-memory>"
const CLOSE = "</claude-code-memory>"

function findMemoryDir(start: string): string | null {
  let dir = start
  for (;;) {
    const candidate = join(homedir(), ".claude", "projects", dir.replace(/[^a-zA-Z0-9]/g, "-"), "memory")
    if (existsSync(join(candidate, "MEMORY.md"))) return candidate
    if (existsSync(join(dir, ".git"))) return null
    const parent = dirname(dir)
    if (parent === dir) return null
    dir = parent
  }
}

function buildBlock(memoryDir: string): string | null {
  try {
    const index = readFileSync(join(memoryDir, "MEMORY.md"), "utf8")
    return [
      OPEN,
      `This is Claude Code's persistent memory for this project, stored in ${memoryDir}.`,
      "Read the linked files with the read tool when they are relevant.",
      "This memory is read-only here: do not create or modify any file in that directory.",
      "",
      index.trim(),
      CLOSE,
    ].join("\n")
  } catch {
    return null
  }
}

const FORWARDED_TAGS = [["<claude-code-memory>", "</claude-code-memory>"], ["<claude-mem-context>", "</claude-mem-context>"]]

function forwardToClaudeAgent(e: any) {
  if (typeof e?.options?.claudeCodeInstructions !== "string") return
  let instructions: string = e.options.claudeCodeInstructions
  for (const part of e.system.slice(1)) {
    const text = part?.text
    if (typeof text !== "string") continue
    const tag = FORWARDED_TAGS.find(([open]) => text.startsWith(open))
    if (!tag) continue
    const [open, close] = tag
    for (let start = instructions.indexOf(open); start !== -1; start = instructions.indexOf(open)) {
      const end = instructions.indexOf(close, start)
      instructions = instructions.slice(0, start) + (end === -1 ? "" : instructions.slice(end + close.length))
    }
    instructions = instructions.trim() ? instructions.trimEnd() + "\n\n" + text : text
  }
  e.options.claudeCodeInstructions = instructions
}

const ClaudeMemoryPlugin = {
  id: "claude-memory",

  async setup(ctx: any) {
    try {
      const directory = ctx?.location?.directory ?? ctx?.directory
      if (typeof directory !== "string" || directory === "") return
      const memoryDir = findMemoryDir(directory)

      await ctx?.session?.hook?.("context", (e: any) => {
        try {
          if (!Array.isArray(e?.system)) return
          for (let i = e.system.length - 1; i >= 0; i--) {
            if (typeof e.system[i]?.text === "string" && e.system[i].text.includes(OPEN)) e.system.splice(i, 1)
          }
          const block = memoryDir ? buildBlock(memoryDir) : null
          if (block) e.system.push({ type: "text", text: block })
          forwardToClaudeAgent(e)
        } catch {}
      })
    } catch {}
  },
}

export default ClaudeMemoryPlugin
export { ClaudeMemoryPlugin }
