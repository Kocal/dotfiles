import { execFile } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"

const script = join(homedir(), ".claude", "deny-guard.sh")

let warned = false

function warnOnce(message: string) {
  if (warned) return
  warned = true
  console.warn(`[deny-guard] ${message}`)
}

function check(command: string): Promise<string | null> {
  return new Promise((resolve) => {
    const child = execFile("bash", [script], { encoding: "utf8", timeout: 5000, windowsHide: true }, (error, stdout) => {
      if (error) {
        warnOnce(`${script} could not run, commands are not checked against permissions.deny`)
        return resolve(null)
      }
      try {
        const out = JSON.parse(String(stdout).trim() || "{}")?.hookSpecificOutput
        resolve(out?.permissionDecision === "deny" ? String(out.permissionDecisionReason ?? "Blocked by permissions.deny") : null)
      } catch {
        warnOnce(`${script} returned output that is not JSON, commands are not checked against permissions.deny`)
        resolve(null)
      }
    })
    child.stdin?.on("error", () => {})
    child.stdin?.end(JSON.stringify({ tool_input: { command } }))
  })
}

const DenyGuardPlugin = {
  id: "deny-guard",

  async setup(ctx: any) {
    if (typeof ctx?.tool?.hook !== "function") {
      console.warn("[deny-guard] ctx.tool.hook is missing, plugin disabled")
      return
    }
    await ctx.tool.hook("execute.before", async (e: any) => {
      const tool = String(e?.tool ?? "").toLowerCase()
      const command = e?.input?.command
      if ((tool !== "bash" && tool !== "shell") || typeof command !== "string" || !command.trim()) return

      const candidates = [command]
      const unwrapped = command.replace(/^\s*rtk\s+/, "")
      if (unwrapped !== command) candidates.push(unwrapped)

      for (const candidate of candidates) {
        const reason = await check(candidate)
        if (reason) throw new Error(reason)
      }
    })
  },
}

export default DenyGuardPlugin
export { DenyGuardPlugin }
