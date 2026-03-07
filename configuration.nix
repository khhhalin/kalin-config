{ pkgs, ... }:

let
  meta = import ./meta.nix;
in
{
  imports = [
    ./hardware-configuration.nix

    ./nix/settings.nix
    ./nix/state.nix

    ./system/boot.nix
    ./system/network.nix
    ./system/time.nix
    ./system/fonts.nix
    ./system/ssh.nix
    ./system/gc.nix

    ./display/fonts.nix
    ./display/power.nix
    ./display/locale-keyboard.nix
    ./display/compositor.nix
    ./display/portals.nix
    ./display/security.nix

    ./shell/zsh.nix
    ./shell/packages.nix

    ./utils/audio.nix
    ./utils/storage.nix
    ./utils/bluetooth.nix
    ./utils/firmware.nix
    ./utils/filemanager.nix
    ./utils/flatpak.nix
    ./utils/apps.nix
    ./utils/packages.nix

    ./containers/services.nix
    ./containers/packages.nix
    ./containers/associations.nix

    ./rice-packages/services.nix
    ./rice-packages/packages.nix
  ];

  # User account
  users.users.${meta.userName} = {
    isNormalUser = true;
    description = meta.fullName;
    extraGroups = [ "wheel" "networkmanager" "input" "uinput" "video" ];
    shell = pkgs.zsh;

    # Required for rootless Podman user namespaces.
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };
}
