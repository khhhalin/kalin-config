{ ... }:

{
  imports = [
    ./hardware/hardware-configuration.nix

    ./system/nix.nix
    ./system/boot.nix
    ./system/network.nix
    ./system/core.nix
    ./system/fonts.nix

    ./environment/display/locale-keyboard.nix
    ./environment/display/compositor.nix
    ./environment/display/hyprland-caelestia.nix
    ./environment/display/portals.nix
    ./environment/display/session.nix
    ./environment/shell.nix
    ./environment/packages.nix
    ./environment/apps.nix
    ./environment/files.nix
    ./environment/nix-ld.nix

    ./hardware/audio.nix
    ./hardware/bluetooth.nix
    ./hardware/peripherals.nix
    ./hardware/windows.nix

    ./containers/default.nix

    ./environment/rice/default.nix

    ./configuration/users.nix
  ];
}
