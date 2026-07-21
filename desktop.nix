# Apps & packages, shell, file manager, nix-ld, quickshell (the "rice").
{ pkgs, lib, inputs, meta, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  dirs = meta.dirs;

  # nixpkgs quickshell is new enough now (0.3.0, same as the old pin) — no
  # flake input needed, only the wrapGAppsHook3 override for GApps schemas.
  quickshell = pkgs.quickshell.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.wrapGAppsHook3 ];
  });

  # Advertise Nautilus as an xdg-desktop-portal FileChooser backend.
  # Nautilus already exposes org.freedesktop.impl.portal.FileChooser on D-Bus;
  # we just need the .portal descriptor so xdg-desktop-portal knows to use it.
  nautilusPortal = pkgs.runCommandLocal "nautilus-portal" { } ''
    mkdir -p $out/share/xdg-desktop-portal/portals
    cat > $out/share/xdg-desktop-portal/portals/nautilus.portal <<'EOF'
    [portal]
    DBusName=org.gnome.Nautilus
    Interfaces=org.freedesktop.impl.portal.FileChooser
    EOF
  '';

  # Zen Browser: force the file picker through xdg-desktop-portal so it uses
  # Nautilus instead of the bundled GTK dialog.
  zenBrowser = (inputs.zen-browser.packages.${system}.default).overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      zenLib=$(find $out/lib -maxdepth 1 -type d -name 'zen-*' | head -1)
      if [ -n "$zenLib" ]; then
        mkdir -p "$zenLib/distribution"
        cat > "$zenLib/distribution/policies.json" <<'EOF'
        {"policies":{"DisableAppUpdate":true,"Preferences":{"widget.use-xdg-desktop-portal.file-picker":{"Value":true,"Status":"locked"}}}}
        EOF
      fi
    '';
  });

  # MIME types handled by the double-click archive extractor.
  archiveMimes = [
    "application/zip"
    "application/x-zip-compressed"
    "application/x-compressed-tar"
    "application/x-bzip-compressed-tar"
    "application/x-xz-compressed-tar"
    "application/x-lzma-compressed-tar"
    "application/x-lzip-compressed-tar"
    "application/x-zstd-compressed-tar"
    "application/x-tar"
    "application/x-7z-compressed"
    "application/x-rar"
    "application/vnd.rar"
    "application/x-rar-compressed"
    "application/x-cbr"
    "application/x-cbz"
    "application/java-archive"
    "application/x-java-archive"
  ];

  # Double-click archive extraction (CachyOS-style behaviour).
  # Creates a folder named after the archive and extracts into it.
  archiveExtractor = let
    runtimePath = pkgs.lib.makeBinPath [
      pkgs.unzip pkgs.p7zip pkgs.gnutar pkgs.gzip pkgs.bzip2 pkgs.xz
      pkgs.lzip pkgs.zstd pkgs.unrar pkgs.file-roller pkgs.libnotify
    ];
  in pkgs.symlinkJoin {
    name = "archive-extractor";
    paths = [
      (pkgs.writeShellScriptBin "archive-extractor" ''
        PATH="${runtimePath}:$PATH"
        set -uo pipefail

        notify() {
          notify-send -a "Archive Extractor" "$1" "$2" 2>/dev/null || true
        }

        for archive in "$@"; do
          [ -f "$archive" ] || continue

          # Strip archive extension(s) for the target folder name.
          dir="''${archive%.*}"
          case "$archive" in
            *.tar.gz|*.tar.bz2|*.tar.xz|*.tar.lz|*.tar.zst|*.tar.Z|*.tar.lzma|*.tgz|*.tbz2|*.txz|*.tlz)
              dir="''${dir%.*}"
              ;;
          esac

          if [ -e "$dir" ]; then
            i=1
            while [ -e "''${dir} ($i)" ]; do
              i=$((i + 1))
            done
            dir="''${dir} ($i)"
          fi

          mkdir -p "$dir"

          status=1
          case "$archive" in
            *.zip|*.ZIP)
              unzip -q "$archive" -d "$dir"
              status=$?
              ;;
            *.tar.gz|*.tgz|*.tar.GZ)
              tar -xzf "$archive" -C "$dir"
              status=$?
              ;;
            *.tar.bz2|*.tbz2)
              tar -xjf "$archive" -C "$dir"
              status=$?
              ;;
            *.tar.xz|*.txz)
              tar -xJf "$archive" -C "$dir"
              status=$?
              ;;
            *.tar.lz|*.tlz)
              tar --lzip -xf "$archive" -C "$dir"
              status=$?
              ;;
            *.tar.zst)
              tar --zstd -xf "$archive" -C "$dir"
              status=$?
              ;;
            *.tar)
              tar -xf "$archive" -C "$dir"
              status=$?
              ;;
            *.gz)
              gunzip -c "$archive" > "$dir/$(basename "''${archive%.gz}")"
              status=$?
              ;;
            *.bz2)
              bunzip2 -c "$archive" > "$dir/$(basename "''${archive%.bz2}")"
              status=$?
              ;;
            *.xz)
              unxz -c "$archive" > "$dir/$(basename "''${archive%.xz}")"
              status=$?
              ;;
            *.7z)
              7z x "$archive" -o"$dir"
              status=$?
              ;;
            *.rar|*.RAR)
              unrar x "$archive" "$dir"/
              status=$?
              ;;
            *)
              notify "Opening with File Roller" "$archive"
              file-roller "$archive" &
              continue
              ;;
          esac

          if [ $status -eq 0 ]; then
            notify "Extracted" "$(basename "$archive") → $(basename "$dir")"
          else
            notify "Extraction failed" "$archive"
          fi
        done
      '')
      (pkgs.makeDesktopItem {
        name = "archive-extractor";
        desktopName = "Extract Archive";
        comment = "Extract archives into a folder on double-click";
        exec = "archive-extractor %F";
        icon = "package-x-generic";
        terminal = false;
        type = "Application";
        categories = [ "Utility" ];
        mimeTypes = archiveMimes;
      })
    ];
  };

  archiveMimeLines = lib.concatMapStrings
    (m: "${m}=archive-extractor.desktop\n")
    archiveMimes;

  # Terminal clipboard-history picker (TUI): cliphist stores every clipboard
  # entry (text and images), fzf lists them with an image preview, selecting
  # one re-copies it. Meant to be run in a terminal, e.g. `foot -e
  # kalin-clip-picker` bound to a key in kalin-wm. Requires the cliphist
  # watcher running in-session (`wl-paste --watch cliphist store &` in
  # kalin-wm's startup command) — this script only reads/re-copies history,
  # it doesn't collect it.
  clipPicker = pkgs.writeShellScriptBin "kalin-clip-picker" ''
    set -uo pipefail
    PATH="${pkgs.lib.makeBinPath [ pkgs.cliphist pkgs.fzf pkgs.wl-clipboard ]}:$PATH"

    entry="$(cliphist list | fzf --reverse --prompt 'clipboard> ' \
      --preview 'echo {} | cliphist decode | head -c 2000' \
      --preview-window 'down:5:wrap')" || exit 0
    [ -n "$entry" ] || exit 0

    echo "$entry" | cliphist decode | wl-copy
  '';

  # Warm-amber fzf app launcher — replaces fuzzel on Super+p / tap-Super. One
  # merged list over GUI .desktop apps + $PATH commands + live tmux sessions,
  # themed to match the bar TUIs and foot. The script lives in the kalin-wm
  # working tree (like the `kalinwm` dev launcher) so theme/behaviour tweaks
  # need no rebuild; this wrapper only pins the tools it needs on PATH (and
  # inherits the rest of PATH so every user command shows up in the $PATH source).
  kalinLaunch = pkgs.writeShellScriptBin "kalin-launch" ''
    export PATH="${pkgs.lib.makeBinPath [
      pkgs.fzf pkgs.foot pkgs.tmux pkgs.util-linux pkgs.python3 pkgs.coreutils
    ]}:$PATH"
    exec ${dirs.kalinWm}/tools/launcher/kalin-launch "$@"
  '';

  # CLI wrappers around kalin-wm's IPC dock/undock commands (see
  # obsidian/ipc-socket.md in the kalin-wm repo). One script exposed under
  # both names — $0 selects the message shape. $KALIN_IPC_SOCKET is set by
  # kalin-wm itself before forking its startup command, so any child process
  # (including these) inherits it. Uses python3's stdlib for the raw
  # AF_UNIX write rather than netcat, since netcat's `-U` unix-socket flag
  # isn't portable across the openbsd/gnu/busybox variants.
  kalinIpc = let
    dock = pkgs.writeShellScriptBin "kalin-dock" ''
      set -euo pipefail
      case "$(basename "$0")" in
        kalin-dock)
          if [ "$#" -ne 5 ]; then
            echo "usage: kalin-dock <appid> <x> <y> <w> <h>" >&2
            exit 1
          fi
          msg="dock $*"
          ;;
        kalin-undock)
          if [ "$#" -ne 1 ]; then
            echo "usage: kalin-undock <appid>" >&2
            exit 1
          fi
          msg="undock $1"
          ;;
      esac
      if [ -z "''${KALIN_IPC_SOCKET:-}" ]; then
        echo "$(basename "$0"): \$KALIN_IPC_SOCKET is not set (not running under kalin-wm?)" >&2
        exit 1
      fi
      exec ${pkgs.python3}/bin/python3 -c '
import os, socket, sys
s = socket.socket(socket.AF_UNIX)
s.connect(os.environ["KALIN_IPC_SOCKET"])
s.send((sys.argv[1] + "\n").encode())
' "$msg"
    '';
  in pkgs.symlinkJoin {
    name = "kalin-ipc";
    paths = [ dock ];
    postBuild = ''ln -s kalin-dock $out/bin/kalin-undock'';
  };

  # sudo askpass helper: a native GUI popup (zenity) that asks for the sudo
  # password on the real desktop, independent of whatever invoked `sudo -A`.
  # Lets an agent (or any script) trigger a privileged command without ever
  # seeing or passing the password itself — sudo hands zenity the prompt,
  # zenity hands sudo the password directly, over a pipe neither the caller
  # nor its stdout/stderr ever touch.
  sudoAskpass = pkgs.writeShellScriptBin "kalin-sudo-askpass" ''
    exec ${pkgs.zenity}/bin/zenity --password --title="sudo authentication"
  '';

  # The docked bar panel TUIs (wifi/bluetooth/mixer/stats/clipboard/battery/
  # display): one Textual suite, source in the kalin-wm repo's tools/bar-tuis
  # (compositor-adjacent — see inputs.kalin-wm, an existing flake input,
  # rather than a hardcoded path, so this stays reproducible/doesn't silently
  # break if the checkout moves). One dispatcher binary, `kalin-bar-tui
  # <panel>`, spawned inside foot by the bar's DockedPanel instances (see
  # quickshell's BottomBar.qml). Backend CLIs are PATH-prefixed here so the
  # panels don't depend on what else happens to be installed; the display
  # backend needs nothing on PATH (kalin-wm IPC via $KALIN_IPC_SOCKET) and
  # bluetooth/battery talk D-Bus (BlueZ/UPower) directly via dbus-fast.
  barTuiEnv = pkgs.python3.withPackages (ps: [ ps.textual ps.textual-image ps.psutil ps.dbus-fast ]);
  barTuis = pkgs.writeShellScriptBin "kalin-bar-tui" ''
    PATH="${pkgs.lib.makeBinPath [
      pkgs.networkmanager pkgs.wireplumber pkgs.pipewire
      pkgs.cliphist pkgs.wl-clipboard pkgs.power-profiles-daemon
      pkgs.foot
    ]}:$PATH"
    export PYTHONPATH=${inputs.kalin-wm}/tools/bar-tuis
    exec ${barTuiEnv}/bin/python3 -m kalin_tuis "$@"
  '';

  # The TUI bottom bar's host terminal (see quickshell's BarHost.qml and the
  # kalin-wm repo's obsidian/implementation/tui-bar.md). kitty rather than
  # foot: the taskbar renders raster app icons over the kitty graphics
  # protocol (textual-image); foot+sixel corrupts rows under Textual and
  # ghostty needs OpenGL 4.3 this host lacks. kitty is deliberately NOT in
  # systemPackages — it exists only as the bar's canvas, not a user terminal.
  # The bar python is invoked by ABSOLUTE path: a bare `python3` under kitty
  # resolves to kitty's own bundled interpreter (nixpkgs wrapper PATH-prefix)
  # — no textual — and the bar crash-loops (found live, 2026-07-17).
  # background must stay exactly Theme.bar/foot's #1e1915 (matching-alpha
  # translucency, same semantics as foot's alpha-mode=matching).
  kalinBarKitty = pkgs.writeShellScriptBin "kalin-bar-kitty" ''
    if [ "$#" -ne 1 ]; then
      echo "usage: kalin-bar-kitty <app-id>" >&2
      exit 2
    fi
    export PYTHONPATH=${inputs.kalin-wm}/tools/bar-tuis
    PATH="${pkgs.lib.makeBinPath [ pkgs.foot barTuis ]}:$PATH"
    exec ${pkgs.kitty}/bin/kitty --config NONE --class="$1" \
      -o background='#1e1915' -o background_opacity=0.88 -o font_size=11 \
      -o font_family='JetBrainsMono Nerd Font' \
      ${barTuiEnv}/bin/python3 -m kalin_tuis bar
  '';

  # Persistent-terminal wrapper: attach-or-create the shared "terminals" tmux
  # session — the browser-of-terminals model: one viewer foot, tmux windows as
  # its tabs, all outliving any foot window and any compositor restart (the
  # server is the kalin-tmux user service). A name arg attaches/creates that
  # session instead (the scratchpad bind uses `kalin-term scratch`). We
  # `unset TMUX` because kalin-wm's spawn() runs apps inside a
  # `tmux new-window -t kalin-apps` supervisor window, so $TMUX is set and a
  # plain attach would be refused as nesting — unsetting it makes the session a
  # normal sibling in the same server. (Part 3's spawn-direct will later drop
  # the redundant supervisor layer.) Closing foot just detaches; Ctrl-D closes
  # a tab as usual.
  kalinTerm = pkgs.writeShellScriptBin "kalin-term" ''
    set -u
    unset TMUX TMUX_PANE
    exec ${pkgs.tmux}/bin/tmux new-session -A -s "''${1:-terminals}"
  '';

  # Raise a viewer window via the compositor IPC (query the state greeting's
  # clients list, then send "focus <id>"); exit 1 if no client with the given
  # app-id (default kalin-terminals) exists so callers can spawn one. Same
  # python AF_UNIX idiom as kalinIpc below.
  kalinTermFocus = pkgs.writeShellScriptBin "kalin-term-focus" ''
    set -u
    if [ -z "''${KALIN_IPC_SOCKET:-}" ]; then
      echo "kalin-term-focus: \$KALIN_IPC_SOCKET is not set (not running under kalin-wm?)" >&2
      exit 1
    fi
    exec ${pkgs.python3}/bin/python3 -c '
import json, os, socket, sys
appid = sys.argv[1] if len(sys.argv) > 1 else "kalin-terminals"
path = os.environ["KALIN_IPC_SOCKET"]
q = socket.socket(socket.AF_UNIX)
q.settimeout(2)
q.connect(path)
state = json.loads(q.makefile("r").readline())
q.close()
for c in state.get("clients", []):
    if c.get("appid") == appid:
        s = socket.socket(socket.AF_UNIX)
        s.settimeout(2)
        s.connect(path)
        s.send(("focus %d\n" % c["id"]).encode())
        s.close()
        sys.exit(0)
sys.exit(1)
' "$@"
  '';

  # Super+T: browser-style "new tab" — add a window to the shared terminals
  # session, then raise the existing viewer foot; only spawn a new foot when
  # none is up (first open, or after a compositor crash — reattaching then
  # restores every tab at once).
  kalinTermTab = pkgs.writeShellScriptBin "kalin-term-tab" ''
    set -u
    tmux=${pkgs.tmux}/bin/tmux
    if $tmux has-session -t terminals 2>/dev/null; then
      $tmux new-window -t terminals -c "$HOME"
    else
      $tmux new-session -d -s terminals
    fi
    ${kalinTermFocus}/bin/kalin-term-focus 2>/dev/null && exit 0
    exec ${pkgs.util-linux}/bin/setsid -f ${pkgs.foot}/bin/foot \
      --app-id=kalin-terminals -e ${kalinTerm}/bin/kalin-term
  '';

  # Tab picker: fuzzel over the windows of the shared terminals session;
  # picking one selects that tab and raises (or spawns) the viewer foot.
  kalinTermPick = pkgs.writeShellScriptBin "kalin-term-pick" ''
    set -uo pipefail
    PATH="${pkgs.lib.makeBinPath [ pkgs.tmux pkgs.fuzzel pkgs.foot ]}:$PATH"
    sel="$(tmux list-windows -t terminals \
      -F '#{window_index}: #{window_name}  ·  #{pane_current_command}  ·  #{pane_current_path}' 2>/dev/null \
      | fuzzel --dmenu --prompt 'tab> ')" || exit 0
    [ -n "$sel" ] || exit 0
    tmux select-window -t "terminals:''${sel%%:*}"
    ${kalinTermFocus}/bin/kalin-term-focus 2>/dev/null && exit 0
    exec foot --app-id=kalin-terminals -e ${kalinTerm}/bin/kalin-term
  '';

  # Standalone-editor window: helix as a peer of Zen/Obsidian in the tab
  # model, not a program inside the terminal-browser (where tmux owns the tab
  # keys). One dedicated tmux session "helix" holding a single hx instance,
  # viewed by its own foot (app-id kalin-helix); tmux.conf translates the
  # universal tab keys into helix buffer commands for this session only, so
  # Ctrl+Tab cycles buffers here while it cycles terminal tabs in "terminals".
  # `kalin-hx [file...]` opens files in the running instance (:open via
  # send-keys) and raises the window; the session dies when hx quits.
  kalinHx = let
    attach = pkgs.writeShellScriptBin "kalin-hx-attach" ''
      set -u
      unset TMUX TMUX_PANE
      exec ${pkgs.tmux}/bin/tmux new-session -A -s helix ${pkgs.helix}/bin/hx
    '';
  in pkgs.writeShellScriptBin "kalin-hx" ''
    set -u
    tmux=${pkgs.tmux}/bin/tmux
    if ! $tmux has-session -t helix 2>/dev/null; then
      $tmux new-session -d -s helix ${pkgs.helix}/bin/hx
      # hx must be up before send-keys, or the :open keys get mangled into
      # the terminal during startup (observed: half-eaten command inserted
      # as buffer text). Poll briefly, then give the UI a beat to settle.
      for _ in $(${pkgs.coreutils}/bin/seq 30); do
        [ "$($tmux display -t helix -p '#{pane_current_command}')" = "hx" ] && break
        ${pkgs.coreutils}/bin/sleep 0.1
      done
      ${pkgs.coreutils}/bin/sleep 0.3
    fi
    for f in "$@"; do
      case "$f" in /*) p="$f" ;; *) p="$PWD/$f" ;; esac
      $tmux send-keys -t helix Escape ":open $p" Enter
    done
    ${kalinTermFocus}/bin/kalin-term-focus kalin-helix 2>/dev/null && exit 0
    exec ${pkgs.util-linux}/bin/setsid -f ${pkgs.foot}/bin/foot \
      --app-id=kalin-helix -e ${attach}/bin/kalin-hx-attach
  '';

  # Compat alias — test-vm/vm.nix and older docs refer to the display panel
  # by this name.
  displayPanel = pkgs.writeShellScriptBin "kalin-display-panel" ''
    exec ${barTuis}/bin/kalin-bar-tui display
  '';
in
{
  # sudo -A uses this to prompt via a GUI popup instead of the tty.
  environment.variables.SUDO_ASKPASS = "${sudoAskpass}/bin/kalin-sudo-askpass";

  # Quickshell bar as a supervised user service so it self-heals. It used to
  # be spawned once by kalin-wm's startup command (`qs &`), so anything that
  # killed it (e.g. the 2026-07-21 tmux-cgroup kill) left the session bar-less
  # until a manual restart or re-login. Restart=always both retries at login
  # until the compositor's wayland-0 socket exists and resurrects the bar
  # after any crash. Pinned to the primary display — the dev launcher
  # (`kalinwm`, separate TTY/display) still spawns its own qs inline.
  systemd.user.services.kalin-bar = {
    description = "Quickshell bar (self-healing)";
    wantedBy = [ "default.target" ];
    path = [ "/run/current-system/sw" ];  # shell.qml spawns kalin-bar-kitty etc.
    environment = {
      QS_CONFIG_PATH = dirs.quickshell;
      WAYLAND_DISPLAY = "wayland-0";
      KALIN_IPC_SOCKET = "%t/kalin-ipc-wayland-0.sock";
    };
    serviceConfig = {
      ExecStart = "${quickshell}/bin/qs";
      Restart = "always";
      RestartSec = 3;
      StartLimitIntervalSec = 0;  # never give up (pre-compositor retries at login)
    };
  };

  # ── Programs with their own options/services ──────────────────────
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # All shell aliases (incl. the kalin-* workflow) live in ~/.zshrc — keep
  # NixOS, including its ls/ll/l defaults, out of the alias business so
  # there's exactly one source of truth.
  environment.shellAliases = lib.mkForce { };
  programs.git = {
    enable = true;
    config.init.defaultBranch = "main";
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Nautilus / GTK ricing: dark mode, list view, show hidden files, nice icons.
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
        icon-theme = "Papyrus-Dark";
      };
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
        show-hidden-files = true;
      };
    };
  }];

  # Default file manager: Nautilus (matches CachyOS Niri + Noctalia setup).
  # Double-clicking archives still extracts via archive-extractor below.
  # This is the ONLY writer of /etc/xdg/mimeapps.list (two writers used to
  # produce duplicate sections) — the .deb handler desktop item itself
  # (debian-deb-install.desktop) is defined in containers.nix.
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    inode/directory=org.gnome.Nautilus.desktop
    ${archiveMimeLines}
    application/vnd.debian.binary-package=debian-deb-install.desktop
    application/x-debian-package=debian-deb-install.desktop
    application/x-deb=debian-deb-install.desktop
    [Added Associations]
    inode/directory=org.gnome.Nautilus.desktop
    ${archiveMimeLines}
    application/vnd.debian.binary-package=debian-deb-install.desktop
    application/x-debian-package=debian-deb-install.desktop
    application/x-deb=debian-deb-install.desktop
  '';

  services.flatpak.enable = true;
  programs.steam.enable = meta.enableSteam;
  virtualisation.waydroid = lib.mkIf meta.enableWaydroid {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  services.power-profiles-daemon.enable = true;

  # nix-ld: run precompiled dynamically-linked executables.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib zlib openssl curl glibc
    libffi ncurses readline sqlite bzip2 xz  # Python/uv et al.
    cacert
  ];

  # ── Plain PATH installs ───────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # shell + core CLI
    starship git gh curl wget gnupg openssh
    unzip zip rsync jq ripgrep fd fzf fastfetch tmux

    # build tools
    gnumake bison gcc binutils file flex

    # wayland session bits
    xwayland-satellite swaylock swayidle swaybg quickshell wlr-randr

    # launchers & terminals (kalinTerm/kalinTermTab/kalinTermPick = shared
    # "terminals" tmux session, see kalin-tmux.nix + obsidian/plan/persistent-desktop.md)
    # kalinLaunch = warm fzf launcher on Super+p / tap-Super (replaces fuzzel).
    # kalinBarKitty = the TUI bottom bar's kitty host (BarHost.qml spawns it).
    fuzzel ghostty foot kalinTerm kalinTermTab kalinTermPick kalinHx kalinLaunch kalinBarKitty

    # screenshots + clipboard
    grim slurp cliphist wl-clipboard clipPicker

    # kalin-wm compositor docking primitive (see obsidian/ipc-socket.md) —
    # provides both kalin-dock and kalin-undock
    kalinIpc

    # sudo askpass GUI popup (zenity), see SUDO_ASKPASS below
    zenity sudoAskpass

    # docked-panel TUI suite (see obsidian/quickshell-shell.md's DockedPanel
    # entry and obsidian/bar-tuis.md in the kalin-wm repo) + the
    # kalin-display-panel compat alias.
    barTuis displayPanel

    # audio / brightness / media
    pamixer playerctl pavucontrol brightnessctl

    # notifications + tray (networkmanagerapplet via programs.nm-applet,
    # blueman via services.blueman)
    libnotify dunst

    # connectivity
    openconnect

    # file management
    nautilus nautilusPortal file-roller xarchiver xdg-utils mutagen archiveExtractor unrar
    papirus-icon-theme

    # browsers
    zenBrowser
    google-chrome  # for the Claude-for-Chrome extension (needs real Chrome, not Zen/Chromium)

    # editors
    helix vscode

    # productivity / monitoring
    obsidian qbittorrent btop gcalcli

    # gaming
    prismlauncher jdk21

    # development
    julia claude-code github-desktop android-studio android-tools

    # qt6 runtime + graphics
    qt6.qtbase qt6.qtdeclarative qt6.qtwayland qt6.qt5compat libGL

    # accessibility / scripting
    python3 orca

    # vesktop: own WebRTC screen share, no reliance on xdg portal ScreenCast
    vesktop vencord
  ]
  ++ lib.optionals meta.enableWaydroid [
    waydroid-nftables
    inputs.waydroid_script.packages.${system}.waydroid_script
    lzip
  ];
}
