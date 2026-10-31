{ config, lib, pkgs, ... }:
let
  # Live path to this repo's claude config (working tree, not the Nix store).
  claudeSrc = "${config.dotfiles.dir}/nix/home/claude";
  link = path: config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/${path}";
  agentsLink = path: config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/agents/${path}";

  chromePlugin = "chrome-devtools-mcp@claude-plugins-official";

  mcpServers = lib.mapAttrs (_: s: { type = "stdio"; inherit (s) command args env; }) config.dotfiles.agents.mcpServers;

  mcpServersJson = pkgs.writeText "claude-mcp-servers.json" (builtins.toJSON mcpServers);

  mergeMcpServers = pkgs.writeShellScript "claude-merge-mcp-servers" ''
    set -euo pipefail
    config="$HOME/.claude.json"
    [ -e "$config" ] || printf '{}\n' > "$config"
    tmp="$(mktemp "$config.XXXXXX")"
    trap 'rm -f "$tmp"' EXIT
    ${pkgs.jq}/bin/jq --slurpfile servers ${mcpServersJson} \
      '.mcpServers = (.mcpServers // {}) + $servers[0]' "$config" > "$tmp"
    mv "$tmp" "$config"
  '';

  warnClaudeCommands = pkgs.writeShellScript "claude-warn-commands" ''
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.diffutils ]}:$PATH"
    dir="''${1:-$HOME/.claude/commands}"
    shared="''${2:-${config.dotfiles.dir}/agents/commands}"
    if [ -L "$dir" ] || [ ! -d "$dir" ]; then
      exit 0
    fi
    for file in "$dir"/*.md; do
      [ -f "$file" ] || continue
      name="$(basename "$file")"
      if [ ! -f "$shared/$name" ]; then
        echo "claude: $file n'existe pas dans $shared, le déplacer dans agents/commands/ et le commiter avant le switch" >&2
      elif ! cmp -s "$file" "$shared/$name"; then
        echo "claude: $file diffère de $shared/$name, reporter les changements dans agents/commands/ et les commiter avant le switch" >&2
      fi
    done
    exit 0
  '';

  syncPluginSkills = pkgs.writeShellScript "claude-sync-plugin-skills" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.jq pkgs.rsync pkgs.diffutils ]}:$PATH"

    skillsDir="${config.dotfiles.dir}/agents/skills"
    gitignore="$skillsDir/.gitignore"
    installed="$HOME/.claude/plugins/installed_plugins.json"

    src=""
    if [ -f "$installed" ]; then
      src="$(jq -r --arg p "${chromePlugin}" '.plugins[$p][0].installPath // empty' "$installed")"
    fi
    if [ -z "$src" ] || [ ! -d "$src/skills" ]; then
      src="$HOME/.claude/plugins/marketplaces/chrome-devtools-plugins"
    fi
    if [ ! -d "$src/skills" ]; then
      echo "claude: pas de source de skills pour ${chromePlugin}, synchronisation ignoree" >&2
      exit 0
    fi

    synced=""
    for dir in "$src"/skills/*/; do
      [ -f "$dir/SKILL.md" ] || continue
      name="$(basename "$dir")"
      rsync -a --delete "$dir" "$skillsDir/$name/"
      synced="$synced$name:"
    done

    if [ -f "$gitignore" ]; then
      grep -v '^#' "$gitignore" | sed 's|^/||;s|/$||' | while read -r previous; do
        [ -n "$previous" ] && [ "$previous" != synced ] || continue
        case ":$synced" in *":$previous:"*) continue ;; esac
        echo "claude: le skill $previous n'existe plus en amont, a supprimer: rm -r $skillsDir/$previous" >&2
      done
    fi

    tmp="$(mktemp "$gitignore.XXXXXX")"
    trap 'rm -f "$tmp"' EXIT
    {
      echo "# Skills synchronisees depuis le plugin ${chromePlugin}."
      echo "# Genere par nix/home/claude.nix a chaque home-manager switch, ne pas editer."
      printf '%s' "$synced" | tr ':' '\n' | grep -v '^$' | sort | sed 's|^|/|;s|$|/|'
      echo "# Skills du compte claude.ai, telecharges par Claude Code a chaque session."
      echo "/synced/"
    } > "$tmp"
    cmp -s "$tmp" "$gitignore" 2>/dev/null || mv "$tmp" "$gitignore"
  '';
in
{
  # Out-of-store symlinks so runtime edits/writes by Claude land back in the repo
  # (a plain `.source = ./file` would copy to a read-only store path, and writes
  # would fail). Whole directories are symlinked so new files (skills, memories)
  # created at runtime also land in the repo.
  home.file = {
    ".claude/settings.json".source = link "settings.json";
    ".claude/statusline-command.sh".source = link "statusline-command.sh";
    ".claude/deny-guard.sh".source = link "deny-guard.sh";
    ".claude/CLAUDE.md".source = agentsLink "AGENTS.md";
    ".claude/agents".source = agentsLink "subagents";
    ".claude/commands".source = agentsLink "commands";
    ".claude/skills".source = agentsLink "skills";
    ".claude/agent-memory".source = link "agent-memory";
  };

  home.activation.claudeWarnCommands =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] "$DRY_RUN_CMD ${warnClaudeCommands} || true";

  # MCP servers can only be declared in ~/.claude.json, which also holds runtime
  # state (history, per-project data, OAuth tokens), so it cannot be symlinked
  # like the files above. The merge overwrites the servers declared here and
  # leaves the rest of the file alone.
  home.activation.claudeMcpServers =
    lib.hm.dag.entryAfter [ "writeBoundary" ] "$DRY_RUN_CMD ${mergeMcpServers}";

  # The chrome-devtools plugin is disabled (its MCP server ships hardcoded args
  # and Claude Code has no way to override them), so its skills are copied in
  # instead. The generated .gitignore keeps them out of the repo.
  home.activation.claudePluginSkills =
    lib.hm.dag.entryAfter [ "writeBoundary" ] "$DRY_RUN_CMD ${syncPluginSkills}";
}
