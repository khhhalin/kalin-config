{ pkgs, inputs, ... }:

let
  # Quickshell pinned to v0.3.0 via the flake input (nixpkgs ships 0.2.x).
  # Needs wrapGAppsHook3 for GApps schemas, so it carries a real override and
  # stays here rather than in packages.nix.
  quickshellPkg = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  quickshellWithQml = quickshellPkg.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.wrapGAppsHook3 ];
  });
in
{
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = [ quickshellWithQml ];
}
