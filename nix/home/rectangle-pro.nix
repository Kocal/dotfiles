{ ... }: {
  # The keys written back when this was a read-only Nix copy persist: re-enable updates.
  targets.darwin.defaults."com.knollsoft.Hookshot" = {
    SUEnableAutomaticChecks = true;
    SUAutomaticallyUpdate = true;
  };
}
