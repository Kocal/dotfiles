{ config, lib, ... }: {
  # Single source of truth for where this repo is checked out on disk.
  # Used for out-of-store symlinks (which must point at a real, editable path,
  # not the read-only Nix store). Can't be auto-derived: flake evaluation is
  # pure, so Nix has no way to know the working-tree location.
  options.dotfiles.dir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/workspace/kocal/dotfiles";
    description = "Absolute path to this dotfiles repo's working tree.";
  };
}
