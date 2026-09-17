{ pkgs, ... }:

{
  home.username = "agent";
  home.homeDirectory = "/home/agent";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    bashInteractive
    coreutils

    # general development tools
    curl
    diffutils
    fd
    file
    findutils
    gawk
    git
    gnugrep
    gnused
    gnutar
    gzip
    jq
    less
    lsof
    patch
    procps
    ripgrep
    tree
    unzip
    wget
    which
    xz
    zip

    # opencode development tools
    opencodesi

    # nix development tools
    nixd
    nixpkgs-fmt

    # C development tools
    clang
    gcc
    make
    cppcheck
    valgrind

    # Go development tools
    go_latest
    go-jsonnet
    golangci-lint
    gopls
    delve

    # TypeScript development tools
    nodejs_26
    bun
    typescript
    oxfmt
    oxlint
    biome

    # jsonnet development tools
    go-jsonnet
  ];

  home.sessionPath = [
    "/home/agent/.nix-profile/bin"
  ];

  programs.home-manager.enable = true;
  programs.bash.enable = true;
}
