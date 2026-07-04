{ config, ... }:
let
  # Live path to this repo's docker config (working tree, not the Nix store).
  dockerSrc = "${config.dotfiles.dir}/nix/home/docker";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dockerSrc}/${path}";
in
{
  # Out-of-store symlink so runtime writes by docker/OrbStack (`docker login`,
  # `docker context use`, ...) land back in the repo instead of failing against a
  # read-only Nix store path -- same reasoning as claude.nix.
  #
  # `credsStore = osxkeychain` uses the credential helper OrbStack ships. A stray
  # `credsStore = ecr-login` (global default, binary gone after the Brew -> Nix
  # migration) is what broke every Docker Hub pull.
  home.file.".docker/config.json".source = link "config.json";
}
