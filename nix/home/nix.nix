{ pkgs, ... }: {
  # The Nix installer's /etc/nix/nix.conf doesn't enable flakes.
  nix.package = pkgs.nix;
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
}
