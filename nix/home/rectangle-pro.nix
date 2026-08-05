{ ... }: {
  # Rectangle Pro is read-only in the Nix store -> Sparkle can't install updates.
  # Disable the background checks. Update via `darwin-rebuild switch`.
  targets.darwin.defaults."com.knollsoft.Hookshot" = {
    SUEnableAutomaticChecks = false;
    SUAutomaticallyUpdate = false;
  };
}
