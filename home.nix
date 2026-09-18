{ pkgs, ... }:
let
  # Import the unstable nixpkgs for use in the configuration
  upkgs = import <nixpkgs-unstable> {
    system = pkgs.stdenv.hostPlatform.system;
  };

  # opencode pinned version
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

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = "__USER__ <opencode-sandbox>";
      user.email = "__USER__@opencode-sandbox.localhost";
      extraConfig.init.defaultBranch = "main";
    };
  };

  home.packages = [
    pkgs.bashInteractive
    pkgs.coreutils

    # general development tools
    pkgs.ast-grep
    pkgs.bat
    pkgs.curl
    pkgs.curlie
    pkgs.delta
    pkgs.difftastic
    pkgs.diffutils
    pkgs.fd
    pkgs.file
    pkgs.findutils
    pkgs.fzf
    pkgs.gawk
    pkgs.gh
    pkgs.git
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gnutar
    pkgs.gzip
    pkgs.hyperfine
    pkgs.jq
    pkgs.less
    pkgs.lsof
    pkgs.openssh
    pkgs.patch
    pkgs.perl
    pkgs.procps
    pkgs.python3
    pkgs.ripgrep
    pkgs.rsync
    pkgs.scc
    pkgs.sd
    pkgs.shellcheck
    pkgs.tokei
    pkgs.tree
    pkgs.unzip
    pkgs.watchexec
    pkgs.wget
    pkgs.which
    pkgs.xz
    pkgs.yq-go
    pkgs.zip

    # opencode development tools
    opencode_1_18_29.opencode

    # nix development tools
    pkgs.nixd

    # C development tools
    pkgs.gcc16
    pkgs.gnumake
    pkgs.cppcheck
    pkgs.valgrind

    # Go development tools
    pkgs.delve
    pkgs.go_1_27
    pkgs.golangci-lint
    pkgs.gopls

    # TypeScript development toolss
    pkgs.biome
    pkgs.bun
    pkgs.nodejs
    pkgs.oxfmt
    pkgs.oxlint
    pkgs.typescript

    # jsonnet development tools
    pkgs.go-jsonnet
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
