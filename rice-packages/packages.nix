{ pkgs, ... }:

let
  quickshellWithQml = pkgs.quickshell.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.wrapGAppsHook3 ];
  });

  pkgsByCategory = {
    compositor = with pkgs; [
      quickshellWithQml
      swaylock
      swayidle
      swaybg
    ];

    terminal = with pkgs; [
      foot
    ];

    launcher = with pkgs; [
      fuzzel
    ];

    monitoring = with pkgs; [
      btop
    ];

    clipboard = with pkgs; [
      cliphist
      wl-clipboard
    ];

    notifications = with pkgs; [
      dunst
    ];

    audio = with pkgs; [
      pavucontrol
    ];

    brightness = with pkgs; [
      brightnessctl
    ];

    screenshots = with pkgs; [
      grim
      slurp
    ];

    keyboard = with pkgs; [
      kanata-with-cmd
    ];

    editors = with pkgs; [
      vscode
    ];

    utilities = with pkgs; [
      python3
      orca
    ];

    qtRuntime = with pkgs; [
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtwayland
      qt6.qt5compat
    ];

    graphics = with pkgs; [
      libGL
    ];

    fileSync = with pkgs; [
      mutagen
    ];
  };

  allPackages = builtins.concatLists (builtins.attrValues pkgsByCategory);
in
{
  environment.systemPackages = allPackages;
}
