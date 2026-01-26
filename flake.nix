{
  description = "Kalin nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-colors.url = "github:misterio77/nix-colors";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dank-material-shell.url = "github:AvengeMedia/DankMaterialShell/stable";

    waydroid_script.url = "github:casualsnek/waydroid_script";

    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = { self, nixpkgs, home-manager, dank-material-shell, nix-colors, waydroid_script, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.KalinBook = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit dank-material-shell nix-colors waydroid_script niri; };

      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        dank-material-shell.nixosModules.dankMaterialShell
        niri.nixosModules.niri
      ];
    };
  };
}
