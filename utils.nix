{ config, pkgs, lib, waydroid_script, ... }:

{
  # Audio (common baseline)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # Removable drives + file manager integration
  services.udisks2.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  programs.thunar = {
    enable = true;
    plugins = [
      pkgs.thunar-archive-plugin
      pkgs.thunar-volman
    ];
  };
  programs.xfconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  users.groups.input = {};
  users.groups.uinput = {};

  # Input remapping: kanata
  # Tap Win = Mod+Space (opens fuzzel via niri bind)
  # Hold Win = normal Super modifier
  services.kanata = {
    enable = true;
    keyboards.default = {
      devices = []; # empty = all keyboards
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc
          lmet
        )

        (defalias
          met (tap-hold-press 200 200 (multi lmet spc) lmet)
        )

        (deflayer base
          @met
        )
      '';
    };
  };

  # uinput access for kanata
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  # The NixOS kanata module uses DynamicUser + strict sandboxing that prevents
  # uinput access.  Run as root with minimal overrides (kanata needs raw input).
  systemd.services.kanata-default.serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateUsers = lib.mkForce false;
    DevicePolicy = lib.mkForce "auto";
    CapabilityBoundingSet = lib.mkForce [ "" ];
    User = lib.mkForce "root";
    Group = lib.mkForce "root";
  };

  # Extras
  programs.firefox.enable = true;
  programs.steam.enable = true;

  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = with pkgs; [
    # build tools
    python3 gnumake bison gcc binutils file flex

    # desktop utils
    xwayland-satellite
    fuzzel
    file-roller
    xdg-utils

    # shell / panel
    quickshell

    # screenshots + clipboard
    grimblast
    wl-clipboard
    slurp
    grim

    # brightness + audio CLI
    brightnessctl
    pamixer
    playerctl

    # idle + lock
    swayidle
    swaylock

    # notifications (fallback if quickshell notif server not running)
    libnotify

    # network applet (tray icon)
    networkmanagerapplet

    # waydroid helpers
    waydroid-nftables
    waydroid_script.packages.${pkgs.system}.waydroid_script
    lzip
  ];
}
