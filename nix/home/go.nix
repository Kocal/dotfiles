{ pkgs, ... }: {
  # Go toolchain. `go build`, `go test`, `go mod`, `go work`, ...
  # gopls = language server (autocomplete/diagnostics VS Code).
  # delve = debugger (binaire `dlv`).
  home.packages = [
    pkgs.go
    pkgs.gopls
    pkgs.delve
  ];

  # `go install` drops binaries in $GOBIN (default $HOME/go/bin); put it on PATH.
  home.sessionPath = [
    "$HOME/go/bin"
  ];
}
