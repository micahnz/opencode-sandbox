{ pkgs, ... }:
let
  # Pin the specific version of nixpkgs using the commit hash
  opencode_1_18_29 = import
    (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/d91a239ca0118ff10ee22ba54f48929c38ab8114.tar.gz";
    })
    { };
in
{
  home.username = "__USER__";
  home.homeDirectory = "/home/__USER__";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    bashInteractive
    coreutils

    # general development tools
    ast-grep
    bat
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
    gnugrep
    gnused
    gnutar
    gzip
    hyperfine
    jq
    less
    lsof
    openssh
    patch
    perl
    procps
    python3
    ripgrep
    rsync
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
    opencode_1_18_29.opencode

    # nix development tools
    nixd

    # C development tools
    gcc16
    gnumake
    cppcheck
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
    "/home/__USER__/.nix-profile/bin"
  ];

  programs.home-manager.enable = true;
  programs.bash.enable = true;

  # Disable 'nix-env' command in the user's shell, prevent agents from using it.
  programs.bash.initExtra = ''
    nix-env() {
      echo "------------------------------------------------------------"
      echo "STOP: 'nix-env' is disabled."
      echo "Please use nix-shell, nix shell or nix develop instead."
      echo "Refer to AGENTS.md for more information."
      echo "------------------------------------------------------------"
      return 1
    }
  '';
}
