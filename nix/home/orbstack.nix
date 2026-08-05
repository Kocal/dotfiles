{ ... }: {
  # OrbStack is read-only in the Nix store -> Sparkle can't install updates, it just
  # nags. Disable the background checks. Update via `darwin-rebuild switch`.
  targets.darwin.defaults."dev.kdrag0n.MacVirt" = {
    SUEnableAutomaticChecks = false;
    SUAutomaticallyUpdate = false;
  };
}
