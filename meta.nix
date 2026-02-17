{
  # ╔══════════════════════════════════════════════════════════════════╗
  # ║  meta.nix — Edit this file to personalize the entire system.   ║
  # ║  Every module reads from here. Change once, applies everywhere.║
  # ╚══════════════════════════════════════════════════════════════════╝

  # ── Machine ────────────────────────────────────────────────────────
  hostName = "KalinBook";           # flake output name: .#KalinBook
  system   = "x86_64-linux";       # or "aarch64-linux" for ARM

  # ── User ───────────────────────────────────────────────────────────
  userName = "kalin";
  fullName = "";                    # shows in login screen / finger

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

  # ── Optional features (set to false to disable) ──────────────────
  enableBluetooth = true;
  enableSteam     = true;
  enableWaydroid  = true;           # Android apps via Waydroid

  # ── Paths (rarely need changing) ──────────────────────────────────
  quickshellConfigPath = "/etc/xdg/quickshell";
  stateVersion = "24.11";          # bump only on NixOS release upgrade
}
