{ config, lib, pkgs, ... }:
let
  skill = "modern-web-guidance";

  checkSkill = pkgs.writeShellScript "modern-web-guidance-check" ''
    if [ ! -f "${config.dotfiles.dir}/agents/skills/${skill}/SKILL.md" ]; then
      echo "${skill}: skill absent, lancer: npx -y modern-web-guidance@latest install -g -a claude-code --copy -y" >&2
    fi
  '';
in
{
  dotfiles.agents.unversionedSkills = [ skill ];

  home.sessionVariables.DISABLE_TELEMETRY = "1";

  home.activation.modernWebGuidanceCheck =
    lib.hm.dag.entryAfter [ "writeBoundary" ] "$DRY_RUN_CMD ${checkSkill}";
}
