{ config, lib, pkgs, ... }:

{
  # Ensure niri has a keybind for Meta+Space (emitted by keyd on Super tap).
  # This keeps the "tap Super opens launcher" workflow composable and avoids keyd command().
  home.activation.niriDmsLauncherBind = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    cfg="$HOME/.config/niri/config.kdl"
    mkdir -p "$(dirname "$cfg")"
    touch "$cfg"

    # Ensure server-side decorations are preferred (titlebar buttons etc).
    if ! ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*prefer-no-csd[[:space:]]*$' "$cfg"; then
      ${pkgs.gawk}/bin/awk '
        BEGIN { inserted = 0 }
        {
          if (!inserted && $0 ~ /^[[:space:]]*input[[:space:]]*\{[[:space:]]*$/) {
            print "prefer-no-csd"
            inserted = 1
          }
          print $0
        }
        END {
          if (!inserted) {
            print ""
            print "prefer-no-csd"
          }
        }
      ' "$cfg" > "$cfg.tmp"
      mv "$cfg.tmp" "$cfg"
    fi

    # Let DMS own wallpaper management (no niri autostart walltheme).
    ${pkgs.gnused}/bin/sed -i \
      -e '/^[[:space:]]*spawn-sh-at-startup[[:space:]]\+".*walltheme[[:space:]].*"[[:space:]]*$/d' \
      "$cfg" || true

    # Remove any existing DMS launcher bind (we re-add it in a known-good form below).
    ${pkgs.gnused}/bin/sed -i \
      -e '/^[[:space:]]*Mod+Space[[:space:]]\+hotkey-overlay-title="App Launcher: DMS"[[:space:]]*{/,/^[[:space:]]*}[[:space:]]*$/d' \
      "$cfg" || true

    # Remove any legacy F13 bind we may have added previously.
    ${pkgs.gnused}/bin/sed -i \
      -e '/^[[:space:]]*F13[[:space:]].*hotkey-overlay-title="App Launcher: DMS"[[:space:]]*{/d' \
      -e '/^[[:space:]]*F13[[:space:]]*{[[:space:]]*$/d' \
      -e '/^[[:space:]]*spawn-sh[[:space:]]*"dms ipc call spotlight toggle";[[:space:]]*$/d' \
      -e '/^[[:space:]]*}[[:space:]]*$/ {x; s/^__DMS_F13_REMOVED__$/&/; x;}' \
      "$cfg" || true

    # If the Mod+Space bind already exists, do nothing.
    if ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*Mod\+Space[[:space:]]+hotkey-overlay-title="App Launcher: DMS"[[:space:]]*\{' "$cfg"; then
      exit 0
    fi

    # Insert into the first `binds {` block if present; otherwise append a minimal one.
    if ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*binds[[:space:]]*\{' "$cfg"; then
      ${pkgs.gawk}/bin/awk '
        BEGIN { inserted = 0 }
        {
          print $0
          if (!inserted && $0 ~ /^[[:space:]]*binds[[:space:]]*\{[[:space:]]*$/) {
            print "  Mod+Space hotkey-overlay-title=\"App Launcher: DMS\" {"
            print "    spawn-sh \"dms ipc call spotlight toggle\";"
            print "  }"
            inserted = 1
          }
        }
      ' "$cfg" > "$cfg.tmp"
      mv "$cfg.tmp" "$cfg"
    else
      cat >> "$cfg" <<'EOF'

binds {
  Mod+Space hotkey-overlay-title="App Launcher: DMS" {
    spawn-sh "dms ipc call spotlight toggle";
  }
}
EOF
    fi
  '';
}
