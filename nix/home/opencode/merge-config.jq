del(.autoupdate) + {
  "$schema": "https://opencode.ai/config.json",
  update: "disable",
  model: "claude-agent/opus#xhigh",
  worktree: {directory: ".claude/worktrees"},
  instructions: ["\($home)/.claude/RTK.md", "\($opencodeSrc)/AGENTS.opencode.md"],
  plugins: [$superpowers],
  permissions: ([{action: "*", resource: "*", effect: "allow"}] + $denies)
}
| .agents = ((.agents // {}) * {
    title: {model: "claude-agent/haiku"},
    build: {model: "claude-agent/opus#xhigh"},
    general: {
      model: "claude-agent/sonnet",
      permissions: [
        {action: "question", resource: "*", effect: "deny"},
        {action: "subagent", resource: "*", effect: "deny"}
      ]
    },
    plan: {
      model: "claude-agent/opus#xhigh",
      permissions: ([
        {action: "edit", resource: "*", effect: "deny"},
        {action: "edit", resource: "\($home)/.opencode/plan/*", effect: "allow"}
      ] + $denies)
    },
    explore: {
      model: "claude-agent/sonnet",
      permissions: [
        {action: "edit", resource: "*", effect: "deny"},
        {action: "subagent", resource: "*", effect: "deny"}
      ]
    }
  })
| .mcp = ((.mcp // {} | del(.["claude-mem"])) + $servers[0] + $claudeMem)
