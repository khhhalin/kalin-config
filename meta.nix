{
  # Host / output name used by flake: .#<hostName>
  hostName = "KalinBook";

  # Target system architecture
  system = "x86_64-linux";

  # Primary interactive user
  userName = "kalin";
  fullName = "";

  # Locale / time
  timeZone = "Europe/Warsaw";
  defaultLocale = "en_US.UTF-8";
  supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "pl_PL.UTF-8/UTF-8"
  ];

  # Keyboard (TTY + X11/Wayland)
  xkb = {
    layout = "pl";
    model = "pc105";
    variant = "";
    options = "terminate:ctrl_alt_bksp";
  };

  # Bump only when upgrading NixOS releases
  stateVersion = "24.11";

  # Path to the quickshell QML config directory
  # (can be overridden per-user if managing dotfiles separately)
  quickshellConfigPath = "/etc/xdg/quickshell";
}
