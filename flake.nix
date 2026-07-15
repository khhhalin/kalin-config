{
  description = "NixOS config — edit meta.nix to personalize";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waydroid_script = {
      url = "github:casualsnek/waydroid_script";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell?ref=refs/tags/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Personal Wayland compositor (dwl fork). Pins its own nixpkgs for wlroots
    # 0.20 — intentionally does NOT follow system nixpkgs, which would break it.
    # path: (not git+file:) so a rebuild picks up staged-but-uncommitted work
    # in that tree without needing a commit first — git+file: only reads
    # committed content, confirmed by prefetching it directly and finding
    # staged new files missing from the fetched source.
    kalin-wm.url = "path:/home/kalin/environment/kalin-wm";
  };

  outputs = inputs@{ nixpkgs, ... }:
  let
    meta = import ./meta.nix;
  in
  {
    # `nix fmt` — note: this normalizes lists to one item per line.
    formatter.${meta.system} = nixpkgs.legacyPackages.${meta.system}.nixfmt;

    nixosConfigurations.${meta.hostName} = nixpkgs.lib.nixosSystem {
      system = meta.system;
      specialArgs = { inherit inputs meta; };
      modules = [
        ./hardware-configuration.nix
        ./system.nix
        ./hardware.nix
        ./display.nix
        ./desktop.nix
        ./containers.nix
        ./users.nix
        ./claude-tty.nix
        ./kalin-tmux.nix
        inputs.niri.nixosModules.niri
      ];
    };
  };
}
