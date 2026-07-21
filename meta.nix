# meta.nix — single source of truth. Every module reads from here.
{
  # ── Machine ────────────────────────────────────────────────────────
  hostName = "KalinBook";          # flake output name: .#KalinBook
  system   = "x86_64-linux";       # or "aarch64-linux" for ARM

  # ── User ───────────────────────────────────────────────────────────
  userName = "kalin";
  fullName = "";                   # shows in login screen / finger

  # ── Locale & time ─────────────────────────────────────────────────
  timeZone      = "Europe/Warsaw";
  defaultLocale = "en_US.UTF-8";
  supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "pl_PL.UTF-8/UTF-8"
  ];

  # ── Keyboard ──────────────────────────────────────────────────────
  xkb = {
    layout  = "pl";
    model   = "pc105";
    variant = "";
    options = "terminate:ctrl_alt_bksp";
  };

  # ── Project directories ────────────────────────────────────────────
  # Single source of truth for every module/alias that points into the
  # working trees. Exception: the kalin-wm flake *input* in flake.nix must
  # stay a literal (inputs can't interpolate) — keep it in sync by hand.
  dirs = {
    homeConfig = "/home/kalin/home-config";
    kalinWm    = "/home/kalin/environment/kalin-wm";
    quickshell = "/home/kalin/environment/quickshell";
    testVm     = "/home/kalin/environment/test-vm";
    fleetDeck  = "/home/kalin/fleet-deck";
  };

  # ── Optional features (set to false to disable) ───────────────────
  enableBluetooth    = true;
  enableSteam        = true;
  enableWaydroid     = true;        # Android apps via Waydroid


  # bump only on NixOS release upgrade (see system.stateVersion in the manual)
  stateVersion = "24.11";
}
