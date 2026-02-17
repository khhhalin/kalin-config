{
  description = "NixOS config — edit meta.nix to personalize";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    waydroid_script.url = "github:casualsnek/waydroid_script";

    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = { self, nixpkgs, waydroid_script, niri, ... }:
  let
    meta = import ./meta.nix;
  in
  {
    nixosConfigurations.${meta.hostName} = nixpkgs.lib.nixosSystem {
      system = meta.system;

      specialArgs = { inherit waydroid_script; };

      modules = [
        ./configuration.nix
        niri.nixosModules.niri
      ];
    };
  };
}
