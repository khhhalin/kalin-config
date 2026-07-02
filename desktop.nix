# Apps & packages, shell, file manager, nix-ld, quickshell (the "rice").
{ pkgs, lib, inputs, meta, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Quickshell pinned to v0.3.0 (nixpkgs ships 0.2.x). Needs wrapGAppsHook3
  # for GApps schemas, so it carries a real override.
  quickshell = (inputs.quickshell.packages.${system}.default).overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.wrapGAppsHook3 ];
  });
in
{
  # ── Programs with their own options/services ──────────────────────
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      # Navigation
      kalin-code = "cd /home/kalin/environment/kalin-wm";
      kalin-shell = "cd /home/kalin/environment/quickshell";
      kalin-vm = "cd /home/kalin/environment/test-vm";
      kalin-home = "cd /home/kalin/home-config";

      # kalin-wm build & test
      kalin-build = "cd /home/kalin/environment/kalin-wm && nix develop -c make clean all";
      kalin-test = "cd /home/kalin/environment/kalin-wm && nix develop -c make test-unit";

      # Runners
      kalin-nested = "cd /home/kalin/environment/kalin-wm && ./scripts/run-nested";
      kalin-tty = "cd /home/kalin/environment/kalin-wm && ./scripts/run-tty";
      kalin-tty3 = "cd /home/kalin/environment/kalin-wm && ./scripts/test-tty3";

      # Test VM
      kalin-vm-build = "cd /home/kalin/environment/test-vm && nix build .#vm";
      kalin-vm-run = "cd /home/kalin/environment/test-vm && timeout 60s env QEMU_OPTS=\"-display egl-headless,gl=on\" ./result/bin/run-kalin-test-vm";
      kalin-vm-logs = "tail -20 /tmp/kalin-vm/kalin-wm.log && tail -20 /tmp/kalin-vm/quickshell.log";

      # Host NixOS rebuild
      kalin-rebuild = "sudo nixos-rebuild switch --flake /home/kalin/home-config#KalinBook";
      kalin-rebuild-build = "nixos-rebuild build --flake /home/kalin/home-config#KalinBook";
    };
  };
  programs.git = {
    enable = true;
    config.init.defaultBranch = "main";
  };
  programs.thunar = {
    enable = true;
    plugins = [ pkgs.thunar-archive-plugin pkgs.thunar-volman ];
  };
  programs.xfconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  services.flatpak.enable = true;
  programs.steam.enable = meta.enableSteam;
  virtualisation.waydroid = lib.mkIf meta.enableWaydroid {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  services.power-profiles-daemon.enable = true;

  # nix-ld: run precompiled dynamically-linked executables.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib zlib openssl curl glibc
    libffi ncurses readline sqlite bzip2 xz  # Python/uv et al.
    cacert
  ];

  # ── Plain PATH installs ───────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # shell + core CLI
    starship git gh curl wget gnupg openssh
    unzip zip rsync jq ripgrep fd fzf fastfetch tmux

    # build tools
    gnumake bison gcc binutils file flex

    # wayland session bits
    xwayland-satellite swaylock swayidle swaybg quickshell

    # launchers & terminals
    fuzzel ghostty foot

    # screenshots + clipboard
    grim slurp cliphist wl-clipboard

    # audio / brightness / media
    pamixer playerctl pavucontrol brightnessctl

    # notifications + tray (networkmanagerapplet via programs.nm-applet,
    # blueman via services.blueman)
    libnotify dunst

    # connectivity
    openconnect

    # keyboard
    kanata-with-cmd

    # file management
    file-roller xdg-utils mutagen

    # browsers
    vivaldi
    inputs.zen-browser.packages.${system}.default

    # editors
    helix vscode

    # productivity / monitoring
    obsidian qbittorrent btop

    # gaming
    prismlauncher jdk21

    # development
    julia claude-code github-desktop

    # qt6 runtime + graphics
    qt6.qtbase qt6.qtdeclarative qt6.qtwayland qt6.qt5compat libGL

    # accessibility / scripting
    python3 orca

    # vesktop: own WebRTC screen share, no reliance on xdg portal ScreenCast
    vesktop vencord
  ]
  ++ lib.optionals meta.enableWaydroid [
    waydroid-nftables
    inputs.waydroid_script.packages.${system}.waydroid_script
    lzip
  ];
}
