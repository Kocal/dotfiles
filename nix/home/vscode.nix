{ ... }: {
  # Disable VS Code's Squirrel self-updater: it stages updates it can't install
  # into the read-only Nix bundle and kills the window on launch. (The app itself
  # is installed via environment.systemPackages so Spotlight indexes a real copy.)
  home.file."Library/Application Support/Code/User/settings.json".text = builtins.toJSON {
    "update.mode" = "none";
    "extensions.autoCheckUpdates" = false;
  };
}
