{ config, lib, pkgs, ... }:
let
  opencodeSrc = "${config.dotfiles.dir}/nix/home/opencode";

  mcpServers = lib.mapAttrs
    (_: s: { type = "local"; command = [ s.command ] ++ s.args; environment = s.env; })
    config.dotfiles.agents.mcpServers;

  mcpServersJson = pkgs.writeText "opencode-mcp-servers.json" (builtins.toJSON mcpServers);

  denyRules = ./opencode/deny-rules.jq;

  mergeConfig = pkgs.writeShellScript "opencode-merge-config" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.diffutils pkgs.jq ]}:$PATH"
    config="$HOME/.config/opencode/opencode.json"
    mkdir -p "$(dirname "$config")"
    [ -f "$config" ] && [ -n "$(tr -d '[:space:]' < "$config")" ] || printf '{}\n' > "$config"
    if ! jq empty "$config" 2>/dev/null; then
      echo "opencode: ~/.config/opencode/opencode.json n'est pas du JSON valide, fusion ignorée" >&2
      exit 0
    fi

    superpowers="superpowers@git+https://github.com/obra/superpowers.git"
    installed="$HOME/.claude/plugins/installed_plugins.json"
    if [ -f "$installed" ]; then
      path="$(jq -r '.plugins["superpowers@claude-plugins-official"][0].installPath // empty' "$installed" 2>/dev/null || true)"
      if [ -n "$path" ] && [ -f "$path/index.js" ]; then
        superpowers="$path"
      fi
    fi

    claudeMem='{}'
    if [ -f "$installed" ]; then
      memPath="$(jq -r '.plugins["claude-mem@thedotmack"][0].installPath // empty' "$installed" 2>/dev/null || true)"
      if [ -n "$memPath" ] && [ -f "$memPath/scripts/mcp-server.cjs" ]; then
        claudeMem="$(jq -nc --arg root "$memPath" '
          { "claude-mem": {
              type: "local",
              command: ["node", "\($root)/scripts/mcp-server.cjs"],
              environment: { CLAUDE_PLUGIN_ROOT: $root }
            } }
        ')"
      fi
    fi

    settings="${config.dotfiles.dir}/nix/home/claude/settings.json"
    if ! jq empty "$settings" 2>/dev/null; then
      echo "opencode: $settings absent ou invalide, fusion ignorée" >&2
      exit 0
    fi
    if ! denies="$(jq -c -f ${denyRules} "$settings" 2>/dev/null)"; then
      echo "opencode: impossible de lire permissions.deny dans $settings, fusion ignorée" >&2
      exit 0
    fi

    tmp="$(mktemp "$config.XXXXXX")"
    trap 'rm -f "$tmp"' EXIT
    jq --slurpfile servers ${mcpServersJson} \
      --argjson denies "$denies" \
      --arg home "$HOME" \
      --arg opencodeSrc ${lib.escapeShellArg opencodeSrc} \
      --arg superpowers "$superpowers" \
      --argjson claudeMem "$claudeMem" \
      -f ${./opencode/merge-config.jq} "$config" > "$tmp"
    if [ ! -s "$tmp" ]; then
      echo "opencode: la fusion a produit un fichier vide, opencode.json inchangé" >&2
      exit 0
    fi
    cmp -s "$tmp" "$config" || mv "$tmp" "$config"
  '';

  syncPluginSkills = pkgs.writeShellScript "opencode-sync-plugin-skills" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.jq pkgs.rsync ]}:$PATH"
    installed="$HOME/.claude/plugins/installed_plugins.json"
    if [ ! -f "$installed" ]; then
      echo "opencode: $installed absent, synchronisation des skills de plugins ignorée" >&2
      exit 0
    fi

    target="$HOME/.config/opencode/skills"
    tmp="$(mktemp -d)"
    trap 'rm -r "$tmp"' EXIT

    for plugin in \
      i-have-adhd@i-have-adhd \
      symfony-ux-skills@symfony-ux-skills \
      symfony-contribution-skills@symfony-contribution-skills \
      skill-creator@claude-plugins-official; do
      path="$(jq -r --arg p "$plugin" '.plugins[$p][0].installPath // empty' "$installed" 2>/dev/null || true)"
      if [ -z "$path" ] || [ ! -d "$path/skills" ]; then
        echo "opencode: plugin $plugin absent, ignoré" >&2
        continue
      fi
      for dir in "$path"/skills/*/; do
        [ -f "$dir/SKILL.md" ] || continue
        name="$(basename "$dir")"
        if [ -e "$HOME/.claude/skills/$name" ] || [ -e "$HOME/.claude/skills/synced/$name" ]; then
          echo "opencode: le skill $name existe déjà dans ~/.claude/skills, ignoré" >&2
          continue
        fi
        rsync -a "$dir" "$tmp/$name/"
      done
    done

    mkdir -p "$target"
    rsync -a --delete "$tmp/" "$target/"
  '';

  syncAgents = pkgs.writeShellScript "opencode-sync-agents" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.jq pkgs.rsync pkgs.yq-go ]}:$PATH"
    src="${config.dotfiles.dir}/agents/subagents"
    if [ ! -d "$src" ]; then
      echo "opencode: $src absent, synchronisation des subagents ignorée" >&2
      exit 0
    fi

    settings="${config.dotfiles.dir}/nix/home/claude/settings.json"
    if ! denies="$(jq -c -f ${denyRules} "$settings" 2>/dev/null)"; then
      echo "opencode: $settings absent ou invalide, synchronisation des subagents ignorée" >&2
      exit 0
    fi

    target="$HOME/.config/opencode/agents"
    tmp="$(mktemp -d)"
    trap 'rm -r "$tmp"' EXIT

    for file in "$src"/*.md; do
      [ -f "$file" ] || continue
      front="$(yq --front-matter=extract -o=json '.' "$file" | jq --argjson denies "$denies" '
        def tool: {
          Read: "read", Glob: "glob", Grep: "grep", LS: "glob",
          Edit: "edit", MultiEdit: "edit", Write: "edit", NotebookEdit: "edit",
          Bash: "shell", WebFetch: "webfetch", WebSearch: "websearch",
          Task: "subagent", Agent: "subagent"
        }[.];
        def model: {
          sonnet: "claude-agent/sonnet", opus: "claude-agent/opus", haiku: "claude-agent/haiku"
        }[.];
        (if .description then { description: .description } else {} end)
        + { mode: "subagent" }
        + (if ((.model // "") | model) then { model: (.model | model) } else {} end)
        + (if .tools then {
            permissions: (
              [ { action: "*", resource: "*", effect: "deny" } ]
              + ([ "read",
                   (.tools | if type == "array" then .[] else split(",")[] end
                    | strings | gsub("^\\s+|\\s+$"; "") | tool | select(.)) ]
                 | unique | map({ action: ., resource: "*", effect: "allow" }))
              + $denies )
          } else {} end)
      ' | yq -P '.')" || { echo "opencode: frontmatter illisible dans $file, subagent ignoré" >&2; continue; }
      {
        echo '---'
        printf '%s\n' "$front"
        echo '---'
        awk '
          /^---[[:space:]]*$/ && fm < 2 { fm++; next }
          fm < 2 { next }
          /^## Update Your Agent Memory/ { skip = 1; next }
          /^## / { skip = 0 }
          !skip { print }
        ' "$file"
      } > "$tmp/$(basename "$file")"
    done

    mkdir -p "$target"
    rsync -a --delete "$tmp/" "$target/"
  '';

  syncCommands = pkgs.writeShellScript "opencode-sync-commands" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.findutils ]}:$PATH"
    src="${config.dotfiles.dir}/agents/commands"
    target="$HOME/.config/opencode/commands"
    if [ ! -d "$src" ]; then
      echo "opencode: $src absent, commandes partagées ignorées" >&2
      exit 0
    fi
    mkdir -p "$target"
    find "$target" -maxdepth 1 -type l -lname "$src/*" ! -exec test -e {} \; -delete
    for file in "$src"/*.md; do
      [ -f "$file" ] || continue
      name="$(basename "$file")"
      if [ -L "$target/$name" ] && [ "$(readlink "$target/$name")" != "$src/$name" ]; then
        echo "opencode: la commande $name est gérée par home-manager, $file ignoré" >&2
        continue
      fi
      ln -sfn "$file" "$target/$name"
    done
  '';

  rtkPlugin = pkgs.writeShellScript "opencode-rtk-plugin" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.diffutils ]}:$PATH"
    rtk=/opt/homebrew/bin/rtk
    if [ ! -x "$rtk" ]; then
      echo "opencode: $rtk absent, plugin rtk ignoré" >&2
      exit 0
    fi

    tmp="$(mktemp -d)" || { echo "opencode: mktemp a échoué, plugin rtk ignoré" >&2; exit 0; }
    if ! output="$(HOME="$tmp" "$rtk" init -g --opencode --hook-only </dev/null 2>&1)"; then
      echo "opencode: rtk init a échoué, plugin rtk ignoré" >&2
      printf '%s\n' "$output" >&2
      exit 0
    fi
    generated="$tmp/.config/opencode/plugins/rtk.ts"
    if [ ! -f "$generated" ]; then
      echo "opencode: rtk n'a pas généré rtk.ts, plugin ignoré" >&2
      exit 0
    fi

    target="$HOME/.config/opencode/plugins/rtk.ts"
    mkdir -p "$(dirname "$target")"
    cmp -s "$generated" "$target" || cp "$generated" "$target"
  '';

  installClaudeMem = pkgs.writeShellScriptBin "opencode-install-claude-mem" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.jq pkgs.nodejs ]}:$PATH"
    installed="$HOME/.claude/plugins/installed_plugins.json"
    version=""
    if [ -f "$installed" ]; then
      version="$(jq -r '.plugins["claude-mem@thedotmack"][0].version // empty' "$installed" 2>/dev/null || true)"
    fi
    if [ -z "$version" ]; then
      echo "opencode: plugin claude-mem@thedotmack absent de $installed" >&2
      exit 1
    fi

    tmp="$(mktemp -d)"
    CLAUDE_MEM_ONLINE_OPTIN=false OPENCODE_CONFIG_DIR="$tmp" npx -y "claude-mem@$version" install --ide opencode </dev/null
    if [ ! -f "$tmp/plugins/claude-mem.js" ]; then
      echo "opencode: l'installeur n'a pas produit plugins/claude-mem.js" >&2
      exit 1
    fi

    mkdir -p "$HOME/.config/opencode/plugins"
    cp "$tmp/plugins/claude-mem.js" "$HOME/.config/opencode/plugins/claude-mem.js"
    ${mergeConfig}
  '';

  claudeMemSharedSources = pkgs.writeShellScript "claude-mem-shared-sources" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.diffutils pkgs.jq ]}:$PATH"
    settings="$HOME/.claude-mem/settings.json"
    if ! jq empty "$settings" 2>/dev/null; then
      echo "claude-mem: $settings absent ou invalide, partage des sources ignoré" >&2
      exit 0
    fi

    tmp="$(mktemp "$settings.XXXXXX")"
    trap 'rm -f "$tmp"' EXIT
    jq '.CLAUDE_MEM_SESSION_START_INCLUDE_ALL_SOURCES = "true"' "$settings" > "$tmp"
    cmp -s "$tmp" "$settings" || mv "$tmp" "$settings"
  '';

  checkClaudeMem = pkgs.writeShellScript "opencode-check-claude-mem" ''
    if [ ! -f "$HOME/.config/opencode/plugins/claude-mem.js" ]; then
      echo "claude-mem: lancer opencode-install-claude-mem" >&2
    fi
  '';
in
{
  home.packages = [ installClaudeMem ];

  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/agents/AGENTS.md";

  home.file.".config/opencode/commands/simplify.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/nix/home/opencode/commands/simplify.md";

  home.file.".config/opencode/plugins/deny-guard.ts".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/nix/home/opencode/plugins/deny-guard.ts";

  home.file.".config/opencode/plugins/claude-memory.ts".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/nix/home/opencode/plugins/claude-memory.ts";

  home.file.".config/opencode/plugins/statusline".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/nix/home/opencode/tui-plugins/statusline";

  home.activation.opencodeConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] "$DRY_RUN_CMD ${mergeConfig}";

  home.activation.opencodeSharedCommands =
    lib.hm.dag.entryAfter [ "writeBoundary" ] "$DRY_RUN_CMD ${syncCommands}";

  home.activation.opencodePluginSkills =
    lib.hm.dag.entryAfter [ "opencodeConfig" ] "$DRY_RUN_CMD ${syncPluginSkills}";

  home.activation.opencodeAgents =
    lib.hm.dag.entryAfter [ "opencodeConfig" ] "$DRY_RUN_CMD ${syncAgents}";

  home.activation.opencodeRtkPlugin =
    lib.hm.dag.entryAfter [ "opencodeConfig" "homebrewBundle" ] "$DRY_RUN_CMD ${rtkPlugin}";

  home.activation.opencodeCheckClaudeMem =
    lib.hm.dag.entryAfter [ "opencodeConfig" ] "$DRY_RUN_CMD ${checkClaudeMem}";

  home.activation.claudeMemSharedSources =
    lib.hm.dag.entryAfter [ "writeBoundary" ] "$DRY_RUN_CMD ${claudeMemSharedSources}";
}
