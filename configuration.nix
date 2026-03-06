{ pkgs, ... }:

let
  meta = import ./meta.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ./system.nix
    ./display.nix
    ./shell.nix
    ./utils.nix
    ./containers.nix
    ./rice-packages.nix
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
