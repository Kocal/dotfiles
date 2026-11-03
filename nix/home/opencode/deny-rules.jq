[(.permissions.deny // [])[]
  | capture("^(?<tool>Bash|Read|Edit)\\((?<resource>.*)\\)$")
  | {action: ({Bash: "shell", Read: "read", Edit: "edit"}[.tool]), resource, effect: "deny"}
  | ., (select(.resource | startswith("**/")) | .resource |= ltrimstr("**/")),
    (select(.action == "shell" and (.resource | test(" \\| [A-Za-z0-9_./-]+$")))
      | (.resource | capture(" \\| (?<target>[A-Za-z0-9_./-]+)$").target) as $t
      | (.resource = $t), (.resource = $t + " -s*"))]
+ [{action: "edit", resource: "~/.claude/projects/*/memory/**", effect: "deny"}]
