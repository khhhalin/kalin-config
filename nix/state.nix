{ ... }:

let
  meta = import ../meta.nix;
in
{
  # ── DO NOT CHANGE (see NixOS manual → system.stateVersion) ────────
  system.stateVersion = meta.stateVersion;
}
