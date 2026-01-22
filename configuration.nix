{ config, pkgs, dank-material-shell, nix-colors, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./system_programs/packages.nix
    ./system_programs/waydroid.nix
    ./system_programs/keyd.nix
    ./system_programs/niri.nix
    ./system_programs/ly.nix
    ./system_programs/dank-material-shell.nix
    ./system_programs/steam.nix
    ./system_programs/zsh.nix
    ./system_programs/firefox.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  networking.hostName = "KalinBook";
  time.timeZone = "Europe/Warsaw";

  fonts = {
    enableDefaultPackages = true;
    fontconfig.enable = true;
  };

  services.upower.enable = true;

  # User account
  users.users.kalin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Home Manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # Import DankMaterialShell's Home Manager module so we can manage per-user
  # defaults and plugins declaratively in home-manager.
  home-manager.sharedModules = [
    dank-material-shell.homeModules.dankMaterialShell.default
    nix-colors.homeManagerModules.default
  ];
  home-manager.extraSpecialArgs = { inherit nix-colors; };
  home-manager.users.kalin = import ./home.nix;

  # DO NOT change this lightly; see the NixOS manual entry for `system.stateVersion`.
  system.stateVersion = "24.11";
}
