{ config, lib, pkgs, ... }:
let
  # Live path to this repo's claude config (working tree, not the Nix store).
  claudeSrc = "${config.dotfiles.dir}/nix/home/claude";
  link = path: config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/${path}";

  chromePlugin = "chrome-devtools-mcp@claude-plugins-official";

  mcpServers = {
    chrome-devtools = {
      type = "stdio";
      command = "npx";
      args = [
        "-y"
        "chrome-devtools-mcp@latest"
        "--category-extensions"
        "--ignore-default-chrome-arg=--enable-automation"
        "--chrome-arg=--disable-blink-features=AutomationControlled"
      ];
      env.CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = "1";
    };
  };

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

  syncPluginSkills = pkgs.writeShellScript "claude-sync-plugin-skills" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.jq pkgs.rsync pkgs.diffutils ]}:$PATH"

    skillsDir="${claudeSrc}/skills"
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
      echo "# Genere par nix/home/claude.nix a chaque darwin-rebuild, ne pas editer."
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
    ".claude/CLAUDE.md".source = link "CLAUDE.md";
    ".claude/agents".source = link "agents";
    ".claude/skills".source = link "skills";
    ".claude/agent-memory".source = link "agent-memory";
  };

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
