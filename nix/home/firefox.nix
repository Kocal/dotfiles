{ ... }: {
  # The keys written back when this was a read-only Nix copy persist: re-enable updates.
  targets.darwin.defaults."org.mozilla.firefox" = {
    EnterprisePoliciesEnabled = true;
    DisableAppUpdate = false;
  };
}
