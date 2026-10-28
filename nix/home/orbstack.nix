{ ... }: {
  # The keys written back when this was a read-only Nix copy persist: re-enable updates.
  targets.darwin.defaults."dev.kdrag0n.MacVirt" = {
    SUEnableAutomaticChecks = true;
    SUAutomaticallyUpdate = true;
  };
}
