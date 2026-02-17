{ pkgs, lib, waydroid_script, ... }:

let
  meta = import ./meta.nix;
in
{
  # ── Audio ──────────────────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # ── Storage ────────────────────────────────────────────────────────
  services.udisks2.enable = true;  # automount USB drives

  # ── Bluetooth (toggle in meta.nix) ────────────────────────────────
  hardware.bluetooth.enable = meta.enableBluetooth;
  services.blueman.enable  = meta.enableBluetooth;

  # ── Firmware updates ───────────────────────────────────────────────
  services.fwupd.enable = true;

  # ── File manager ───────────────────────────────────────────────────
  programs.thunar = {
    enable = true;
    plugins = [ pkgs.thunar-archive-plugin pkgs.thunar-volman ];
  };
  programs.xfconf.enable = true;
  services.gvfs.enable    = true;
  services.tumbler.enable = true;

  # ── Input groups (for kanata uinput access) ────────────────────────
 # users.groups.input  = {};
 # users.groups.uinput = {};

  # ── Kanata (keyboard remapper) ─────────────────────────────────────
  # Uses kanata-with-cmd so it can drive niri via IPC.
  # Config lives in ~/.config/kanata/config.kbd (user dotfile).
 # systemd.services.kanata = {
  #  description = "Kanata keyboard remapper";
   # wantedBy    = [ "multi-user.target" ];
   # serviceConfig = {
    #  Type       = "notify";
     # ExecStart  = "${lib.getExe pkgs.kanata-with-cmd} --cfg /home/${meta.userName}/.config/kanata/config.kbd";
  #    Restart    = "on-failure";
   #   RestartSec = 3;
   #   SupplementaryGroups = [ "input" "uinput" ];
   # };
 # };
#  services.udev.extraRules = ''
#    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
#  '';

  # ── Apps (toggles in meta.nix) ─────────────────────────────────────
  programs.steam.enable   = meta.enableSteam;

  virtualisation.waydroid = lib.mkIf meta.enableWaydroid {
    enable  = true;
    package = pkgs.waydroid-nftables;
  };

  # ── System packages ────────────────────────────────────────────────
  environment.systemPackages = with pkgs;
    [
      # build tools
      python3 gnumake bison gcc binutils file flex

      # desktop
      xwayland-satellite fuzzel file-roller xdg-utils
      kanata-with-cmd quickshell

      # screenshots + clipboard
      grimblast wl-clipboard slurp grim

      # brightness / audio / media
      brightnessctl pamixer playerctl

      # idle + lock
      swayidle swaylock

      # notifications + tray
      libnotify networkmanagerapplet

      vivaldi
      vscode
    ]
    # waydroid helpers (only when enabled)
    ++ lib.optionals meta.enableWaydroid [
      waydroid-nftables
      waydroid_script.packages.${pkgs.system}.waydroid_script
      lzip
    ];

}
