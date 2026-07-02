{ config, ... }:
let
  # Live path to this repo's claude config (working tree, not the Nix store).
  claudeSrc = "${config.dotfiles.dir}/nix/home/claude";
  link = path: config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/${path}";
in
{
  # Out-of-store symlinks so runtime edits/writes by Claude land back in the repo
  # (a plain `.source = ./file` would copy to a read-only store path, and writes
  # would fail). Whole directories are symlinked so new files (skills, memories)
  # created at runtime also land in the repo.
  home.file = {
    ".claude/settings.json".source = link "settings.json";
    ".claude/statusline-command.sh".source = link "statusline-command.sh";
    ".claude/CLAUDE.md".source = link "CLAUDE.md";
    ".claude/agents".source = link "agents";
    ".claude/skills".source = link "skills";
    ".claude/agent-memory".source = link "agent-memory";
  };
}
