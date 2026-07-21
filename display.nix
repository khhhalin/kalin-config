# Compositors (niri + kalin-wm), display manager, locale/keyboard, portals.
{ config, pkgs, lib, inputs, meta, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  dirs = meta.dirs;
  kalinPkg = inputs.kalin-wm.packages.${system}.default;

  # Start kalin-wm with a terminal server; the quickshell bar is NOT spawned
  # here anymore — it runs as the self-healing kalin-bar user service (see
  # desktop.nix), which retries until the compositor socket exists.
  kalinSession = pkgs.writeShellScriptBin "kalin-wm-session" ''
    export QS_CONFIG_PATH="${dirs.quickshell}"
    exec ${kalinPkg}/bin/kalin-wm -s 'foot --server'
  '';

  # Dev launcher: run the LOCAL working-tree build (build/kalin-wm) with the
  # shell + terminal, on whatever TTY you're logged into, no timeout. Use this
  # from a text console (e.g. Ctrl+Alt+F3) to see your latest changes. The ly
  # "kalin-wm" session above uses the pinned flake build instead.
  kalinDev = pkgs.writeShellScriptBin "kalinwm" ''
    set -euo pipefail
    root=${dirs.kalinWm}
    bin="$root/build/kalin-wm"
    export QS_CONFIG_PATH=${dirs.quickshell}
    # Paper-mode shaders need the custom-GLSL-capable GLES2 renderer and an
    # absolute shader dir (config `shaders_dir` is CWD-relative and this runs
    # from your login cwd, not the repo root — without this the subsystem logs
    # "cannot read shaders/paper.frag" and self-disables). See obsidian shaders.md.
    export WLR_RENDERER=gles2
    export KALIN_SHADER_DIR="$root/shaders"
    if [ ! -x "$bin" ]; then
      echo "kalinwm: dev build missing — building (nix develop -c make)…"
      ( cd "$root" && nix develop -c make clean all )
    fi
    ${pkgs.procps}/bin/pgrep -x seatd >/dev/null || sudo systemctl start seatd 2>/dev/null || true
    # Log to the screen AND /tmp/kalinwm.log so diagnostics are readable afterwards.
    "$bin" -s 'qs & foot --server' 2>&1 | tee /tmp/kalinwm.log
  '';

  # Portal routing for a screencast/screenshot backend; everything else → gtk.
  # FileChooser is routed to Nautilus so the file picker dialog is the actual
  # file manager instead of the bundled GTK chooser.
  routeVia = backend: {
    default = [ backend "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ backend ];
    "org.freedesktop.impl.portal.Screenshot" = [ backend ];
    "org.freedesktop.impl.portal.FileChooser" = [ "nautilus" ];
    "org.freedesktop.impl.portal.Access" = [ "gtk" ];
    "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
  };
  luminous = routeVia "luminous";
in
{
  # ── Compositors + display manager ─────────────────────────────────
  services.seatd.enable = true;  # DRM/input access for Wayland compositors

  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${system}.niri-unstable;  # native `include`
  };

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings.waylandsessions = "/etc/wayland-sessions";

  environment.systemPackages = [ kalinPkg kalinSession kalinDev ];  # handy for nested testing / IPC; kalinDev = `kalinwm`

  environment.etc."wayland-sessions/niri.desktop".text = ''
    [Desktop Entry]
    Name=niri
    Comment=Wayland compositor (niri)
    Exec=${config.programs.niri.package}/bin/niri
    DesktopNames=niri
    Type=Application
  '';
  environment.etc."wayland-sessions/kalin-wm.desktop".text = ''
    [Desktop Entry]
    Name=kalin-wm
    Comment=Personal Wayland compositor (infinite canvas, dwl fork)
    Exec=${kalinSession}/bin/kalin-wm-session
    DesktopNames=kalin-wm
    Type=Application
  '';

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ── Session services ──────────────────────────────────────────────
  services.upower.enable = true;
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # ── Locale & keyboard ─────────────────────────────────────────────
  i18n.supportedLocales = meta.supportedLocales;
  i18n.defaultLocale = meta.defaultLocale;
  services.xserver.enable = true;
  services.xserver.xkb = {
    inherit (meta.xkb) layout model variant options;
  };
  console.useXkbConfig = true;
  environment.variables = {
    XKB_DEFAULT_LAYOUT = meta.xkb.layout;
    XKB_DEFAULT_MODEL = meta.xkb.model;
    XKB_DEFAULT_VARIANT = meta.xkb.variant;
    XKB_DEFAULT_OPTIONS = meta.xkb.options;
  };

  # ── Portals ───────────────────────────────────────────────────────
  # gnome-portal refuses ScreenCast under niri (wants Mutter.ServiceChannel);
  # luminous uses zwlr-screencopy-v1, which niri implements. (wlr portal is
  # out: it needs zwlr-output-management-v1, which niri omits.)
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-luminous  # ScreenCast + Screenshot
      pkgs.xdg-desktop-portal-gtk       # FileChooser, Access, Notification
    ];
    config.common = luminous;
    config.niri = luminous;  # XDG_CURRENT_DESKTOP may be "niri" or "Niri"
    config."Niri" = luminous;
  };
}
