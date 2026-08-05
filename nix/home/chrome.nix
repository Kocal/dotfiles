{ ... }: {
  # Keystone (Chrome's background updater) checks for updates and shows the
  # "update available" notification. checkInterval = 0 stops the checks, so no
  # more nag. Chrome comes from the homebrew cask, so update it manually with
  # `brew upgrade --cask google-chrome`.
  targets.darwin.defaults."com.google.Keystone.Agent".checkInterval = 0;
}
