{ ... }:

let
  meta = import ../configuration/meta.nix;
in
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Silence the "Git tree is dirty" warning on every rebuild.
    warn-dirty = false;
  };

  nixpkgs.config.allowUnfree = true;
  #nixpkgs.config.permittedInsecurePackages = [ "qtwebengine-5.15.19" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    # Catch up on missed GC runs (e.g. laptop was asleep).
    persistent = true;
  };

  nix.optimise.automatic = true;

  # ── DO NOT CHANGE (see NixOS manual → system.stateVersion) ────────
  system.stateVersion = meta.stateVersion;
}
