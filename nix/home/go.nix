{ pkgs, ... }: {
  # Go toolchain. `go build`, `go test`, `go mod`, `go work`, ...
  # gopls = language server (autocomplete/diagnostics VS Code).
  # delve = debugger (binaire `dlv`).
  home.packages = [
    pkgs.go
    pkgs.gopls
    pkgs.delve
  ];
}
