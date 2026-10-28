{ ... }: {
  # `go install` drops binaries in $GOBIN (default $HOME/go/bin); put it on PATH.
  home.sessionPath = [
    "$HOME/go/bin"
  ];
}
