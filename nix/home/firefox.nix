{ ... }: {
  # firefox-bin is read-only in the Nix store -> its updater nags; kill it via the
  # macOS enterprise policy. Update via `darwin-rebuild switch`.
  targets.darwin.defaults."org.mozilla.firefox" = {
    EnterprisePoliciesEnabled = true;
    DisableAppUpdate = true;
  };
}
