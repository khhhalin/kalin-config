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
  ];

  # User account
  users.users.${meta.userName} = {
    isNormalUser = true;
    description = meta.fullName;
    extraGroups = [ "wheel" "networkmanager" "input" "uinput" "video" ];
    shell = pkgs.zsh;
  };
}
