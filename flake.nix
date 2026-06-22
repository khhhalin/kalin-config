{
  description = "NixOS config — edit meta.nix to personalize";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waydroid_script.url = "github:casualsnek/waydroid_script";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia_shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell?ref=refs/tags/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
  let
    meta = import ./configuration/meta.nix;
  in
  {
    nixosConfigurations.${meta.hostName} = nixpkgs.lib.nixosSystem {
      system = meta.system;

      specialArgs = { inherit inputs; };

      modules = [
        ./configuration.nix
        inputs.niri.nixosModules.niri
      ];
    };
  };
}
