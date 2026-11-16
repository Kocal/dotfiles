{ config, lib, pkgs, ... }:
let
  chromeProfile = "${config.home.homeDirectory}/.cache/chrome-devtools-mcp/chrome-profile";

  # One MCP server per Claude session, so they all share one debug Chrome instead of fighting over the profile lock.
  chromeDevtoolsMcp = pkgs.writeShellScript "chrome-devtools-mcp-shared" ''
    set -eu
    export PATH="${lib.makeBinPath [ pkgs.curl pkgs.coreutils ]}:$PATH"
    url="http://127.0.0.1:9222"

    if ! curl -sf "$url/json/version" >/dev/null; then
      /usr/bin/open -na "Google Chrome Canary" --args --remote-debugging-port=9222 \
        --user-data-dir="${chromeProfile}" \
        --disable-blink-features=AutomationControlled
      for _ in $(seq 1 50); do curl -sf "$url/json/version" >/dev/null && break; sleep 0.2; done
    fi

    exec npx --prefix "$HOME" -y chrome-devtools-mcp@latest --category-extensions --browserUrl "$url"
  '';

  # A beforeunload dialog held by the MCP makes this Chrome ignore the logout's quit request, which aborts restarts and updates.
  chromeDevtoolsQuitOnLogout = pkgs.writeShellScript "chrome-devtools-mcp-quit-on-logout" ''
    set -u
    event="''${1:-com.apple.system.loginwindow.likelyUserSessionExit}"

    while /usr/bin/notifyutil -q -1 "$event"; do
      echo "$(/bin/date '+%F %T') $event -> SIGTERM"
      /usr/bin/pkill -TERM -f -- "--user-data-dir=${chromeProfile}" || true
    done
  '';
in
{
  options.dotfiles.agents.mcpServers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        command = lib.mkOption { type = lib.types.str; };
        args = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
        env = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = { }; };
      };
    });
    default = { };
    description = "MCP servers shared by every coding agent (Claude Code, OpenCode).";
  };

  options.dotfiles.agents.unversionedSkills = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Skills installed by hand into agents/skills/ and kept out of git.";
  };

  config.dotfiles.agents.mcpServers.chrome-devtools = {
    command = "${chromeDevtoolsMcp}";
    env.CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = "1";
  };

  config.launchd.agents.chrome-devtools-mcp-quit-on-logout = {
    enable = true;
    config = {
      ProgramArguments = [ "${chromeDevtoolsQuitOnLogout}" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/chrome-devtools-mcp-quit-on-logout.log";
    };
  };
}
