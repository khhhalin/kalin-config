# Apps & packages, shell, file manager, nix-ld, quickshell (the "rice").
{ pkgs, lib, inputs, meta, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Quickshell pinned to v0.3.0 (nixpkgs ships 0.2.x). Needs wrapGAppsHook3
  # for GApps schemas, so it carries a real override.
  quickshell = (inputs.quickshell.packages.${system}.default).overrideAttrs (old: {
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

  # CLI wrappers around kalin-wm's IPC dock/undock commands (see
  # obsidian/ipc-socket.md in the kalin-wm repo). $KALIN_IPC_SOCKET is set by
  # kalin-wm itself before forking its startup command, so any child process
  # (including these) inherits it. Uses python3's stdlib for the raw
  # AF_UNIX write rather than netcat, since netcat's `-U` unix-socket flag
  # isn't portable across the openbsd/gnu/busybox variants.
  kalinDock = pkgs.writeShellScriptBin "kalin-dock" ''
    set -euo pipefail
    if [ "$#" -ne 5 ]; then
      echo "usage: kalin-dock <appid> <x> <y> <w> <h>" >&2
      exit 1
    fi
    if [ -z "''${KALIN_IPC_SOCKET:-}" ]; then
      echo "kalin-dock: \$KALIN_IPC_SOCKET is not set (not running under kalin-wm?)" >&2
      exit 1
    fi
    exec ${pkgs.python3}/bin/python3 -c '
import os, socket, sys
s = socket.socket(socket.AF_UNIX)
s.connect(os.environ["KALIN_IPC_SOCKET"])
s.send(("dock " + " ".join(sys.argv[1:]) + "\n").encode())
' "$@"
  '';

  kalinUndock = pkgs.writeShellScriptBin "kalin-undock" ''
    set -euo pipefail
    if [ "$#" -ne 1 ]; then
      echo "usage: kalin-undock <appid>" >&2
      exit 1
    fi
    if [ -z "''${KALIN_IPC_SOCKET:-}" ]; then
      echo "kalin-undock: \$KALIN_IPC_SOCKET is not set (not running under kalin-wm?)" >&2
      exit 1
    fi
    exec ${pkgs.python3}/bin/python3 -c '
import os, socket, sys
s = socket.socket(socket.AF_UNIX)
s.connect(os.environ["KALIN_IPC_SOCKET"])
s.send(("undock " + sys.argv[1] + "\n").encode())
' "$@"
  '';

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
  barTuiEnv = pkgs.python3.withPackages (ps: [ ps.textual ps.psutil ps.dbus-fast ]);
  barTuis = pkgs.writeShellScriptBin "kalin-bar-tui" ''
    PATH="${pkgs.lib.makeBinPath [
      pkgs.networkmanager pkgs.wireplumber pkgs.pipewire
      pkgs.cliphist pkgs.wl-clipboard pkgs.power-profiles-daemon
    ]}:$PATH"
    export PYTHONPATH=${inputs.kalin-wm}/tools/bar-tuis
    exec ${barTuiEnv}/bin/python3 -m kalin_tuis "$@"
  '';

  # Persistent-terminal wrapper: attach-or-create a tmux session that outlives
  # this foot window and any compositor restart (the server is the kalin-tmux
  # user service). With no arg each new terminal mints a fresh, uniquely-named
  # session so terminals are independent; a given name reattaches that session
  # (used by kalin-term-pick). We `unset TMUX` because kalin-wm's spawn() runs
  # apps inside a `tmux new-window -t kalin-apps` supervisor window, so $TMUX is
  # set and a plain attach would be refused as nesting — unsetting it makes the
  # per-terminal session a normal sibling in the same server. (Part 3's
  # spawn-direct will later drop the redundant supervisor layer.) Closing foot
  # just detaches; Ctrl-D ends the session as usual.
  kalinTerm = pkgs.writeShellScriptBin "kalin-term" ''
    set -u
    unset TMUX TMUX_PANE
    name="''${1:-term-$(${pkgs.coreutils}/bin/date +%H%M%S)}"
    exec ${pkgs.tmux}/bin/tmux new-session -A -s "$name"
  '';

  # Session picker: fuzzel over the live tmux sessions (plus a "new terminal"
  # entry), opening the chosen one in a fresh foot. Reattaching a session that
  # already has a client just mirrors it (normal tmux).
  kalinTermPick = pkgs.writeShellScriptBin "kalin-term-pick" ''
    set -uo pipefail
    PATH="${pkgs.lib.makeBinPath [ pkgs.tmux pkgs.fuzzel pkgs.foot pkgs.coreutils ]}:$PATH"
    sel="$( { echo "＋ new terminal"; \
      tmux list-sessions -F '#{session_name}  ·  #{session_windows}w#{?session_attached, (attached),}' 2>/dev/null; } \
      | fuzzel --dmenu --prompt 'terminal> ' )" || exit 0
    [ -n "$sel" ] || exit 0
    if [ "$sel" = "＋ new terminal" ]; then
      exec foot -e kalin-term
    fi
    exec foot -e kalin-term "''${sel%%  ·  *}"
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

  # ── Programs with their own options/services ──────────────────────
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      # Navigation
      kalin-code = "cd /home/kalin/environment/kalin-wm";
      kalin-shell = "cd /home/kalin/environment/quickshell";
      kalin-vm = "cd /home/kalin/environment/test-vm";
      kalin-home = "cd /home/kalin/home-config";

      # kalin-wm build & test
      kalin-build = "cd /home/kalin/environment/kalin-wm && nix develop -c make clean all";
      kalin-test = "cd /home/kalin/environment/kalin-wm && nix develop -c make test-unit";

      # Runners
      kalin-nested = "cd /home/kalin/environment/kalin-wm && ./scripts/run-nested";
      kalin-tty = "cd /home/kalin/environment/kalin-wm && ./scripts/run-tty";
      kalin-tty3 = "cd /home/kalin/environment/kalin-wm && ./scripts/test-tty3";

      # Test VM
      kalin-vm-build = "cd /home/kalin/environment/test-vm && nix build .#vm";
      kalin-vm-run = "cd /home/kalin/environment/test-vm && timeout 60s env QEMU_OPTS=\"-display egl-headless,gl=on\" ./result/bin/run-kalin-test-vm";
      kalin-vm-logs = "tail -20 /tmp/kalin-vm/kalin-wm.log && tail -20 /tmp/kalin-vm/quickshell.log";

      # Host NixOS rebuild. kalin-wm is a path: input that tracks the live
      # working tree (see flake.nix), so every rebuild overrides it fresh and
      # skips writing the lock file — otherwise any uncommitted change over
      # there makes home-config's build fail on a stale NAR hash.
      kalin-rebuild = "sudo nixos-rebuild switch --flake /home/kalin/home-config#KalinBook --override-input kalin-wm path:/home/kalin/environment/kalin-wm --no-write-lock-file";
      kalin-rebuild-build = "nixos-rebuild build --flake /home/kalin/home-config#KalinBook --override-input kalin-wm path:/home/kalin/environment/kalin-wm --no-write-lock-file";
    };
  };
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
  environment.etc."xdg/mimeapps.list".text = lib.mkAfter ''
    [Default Applications]
    inode/directory=org.gnome.Nautilus.desktop
    ${archiveMimeLines}
    [Added Associations]
    inode/directory=org.gnome.Nautilus.desktop
    ${archiveMimeLines}
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

    # launchers & terminals (kalinTerm/kalinTermPick = persistent tmux sessions,
    # see kalin-tmux.nix + obsidian/plan/persistent-desktop.md)
    fuzzel ghostty foot kalinTerm kalinTermPick

    # screenshots + clipboard
    grim slurp cliphist wl-clipboard clipPicker

    # kalin-wm compositor docking primitive (see obsidian/ipc-socket.md)
    kalinDock kalinUndock

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
    vivaldi
    zenBrowser

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
