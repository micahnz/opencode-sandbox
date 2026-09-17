{ pkgs, ... }:

{
  home.username = "agent";
  home.homeDirectory = "/home/agent";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    bashInteractive
    coreutils

    # general development tools
    ast-grep
    bat
    comby
    curl
    curlie
    delta
    difftastic
    diffutils
    fd
    file
    findutils
    fzf
    gawk
    gh
    git
    gnutar
    gzip
    hyperfine
    jq
    less
    lsof
    patch
    procps
    ripgrep
    scc
    sd
    shellcheck
    tokei
    tree
    unzip
    watchexec
    wget
    which
    xz
    yq-go
    zip

    # opencode development tools
    opencodesi

    # nix development tools
    nixd

    # C development tools
    clang
    clang-tools
    cppcheck
    make
    valgrind

    # Go development tools
    delve
    go_latest
    golangci-lint
    gopls

    # TypeScript development tools
    biome
    bun
    nodejs_26
    vtsls
    oxfmt
    oxlint
    typescript

    # jsonnet development tools
    go-jsonnet
  ];

  home.sessionPath = [
    "/home/agent/.nix-profile/bin"
  ];

  programs.home-manager.enable = true;
  programs.bash.enable = true;
}
