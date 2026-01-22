{ pkgs, ... }:

let
  walltheme = pkgs.writeShellScriptBin "walltheme" ''
    set -euo pipefail

    if [ "$#" -ge 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
      echo "Usage: walltheme <image-path> [dark|light]" >&2
      exit 0
    fi

    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
      echo "Usage: walltheme <image-path> [dark|light]" >&2
      exit 2
    fi

    img="$1"
    if [ "$#" -ge 2 ]; then
      mode="$2"
    else
      mode="dark"
    fi

    if [ ! -f "$img" ]; then
      echo "walltheme: file not found: $img" >&2
      exit 2
    fi

    if [ "$mode" != "dark" ] && [ "$mode" != "light" ]; then
      echo "walltheme: mode must be 'dark' or 'light'" >&2
      exit 2
    fi

    # Ensure wallpaper daemon is up, then set wallpaper.
    systemctl --user start swww.service >/dev/null 2>&1 || true
    ${pkgs.swww}/bin/swww img "$img"

    # Ask DMS to generate a matugen theme (also updates ~/.cache/DankMaterialShell/dms-colors.json).
    dms matugen queue \
      --kind image \
      --mode "$mode" \
      --value "$img" \
      --wait

    colors_json="$HOME/.cache/DankMaterialShell/dms-colors.json"
    if [ ! -f "$colors_json" ]; then
      echo "walltheme: expected $colors_json to exist after DMS matugen; not found" >&2
      exit 1
    fi

    # Extract a key from the selected mode section of dms-colors.json.
    # We avoid jq/python to keep deps minimal.
    dark_block() {
      awk 'BEGIN{f=0} /"dark"[[:space:]]*:[[:space:]]*{/{f=1;next} f && /"light"[[:space:]]*:[[:space:]]*{/{exit} f{print}' "$colors_json"
    }

    light_block() {
      awk 'BEGIN{f=0} /"light"[[:space:]]*:[[:space:]]*{/{f=1;next} f{print}' "$colors_json"
    }

    get_color() {
      key="$1"
      if [ "$mode" = "dark" ]; then
        line=$(dark_block | grep -m1 "\"$key\"" || true)
      else
        line=$(light_block | grep -m1 "\"$key\"" || true)
      fi

      if [ -z "$line" ]; then
        echo "walltheme: could not find key '$key' in $colors_json ($mode)" >&2
        exit 1
      fi

      echo "$line" | sed -E 's/.*:[[:space:]]*"(#?[0-9a-fA-F]{6})".*/\1/'
    }

    strip_hash() {
      echo "$1" | sed 's/^#//'
    }

    # Terminal-friendly palette mapping from Material keys.
    #
    # Material's `background` can be quite tinted by the wallpaper; for terminals
    # that often reads as "muddy". Using the lowest surface container keeps it
    # darker and more neutral while still matching the wallpaper's hue family.
    background=$(strip_hash "$(get_color surface_container_lowest)")
    foreground=$(strip_hash "$(get_color on_surface)")

    regular0=$(strip_hash "$(get_color surface_container_low)")
    bright0=$(strip_hash "$(get_color surface_container_highest)")

    regular1=$(strip_hash "$(get_color error_container)")
    bright1=$(strip_hash "$(get_color error)")

    regular2=$(strip_hash "$(get_color tertiary_container)")
    bright2=$(strip_hash "$(get_color tertiary)")

    regular3=$(strip_hash "$(get_color secondary_container)")
    bright3=$(strip_hash "$(get_color secondary)")

    regular4=$(strip_hash "$(get_color primary_container)")
    bright4=$(strip_hash "$(get_color primary)")

    regular5=$(strip_hash "$(get_color surface_variant)")
    bright5=$(strip_hash "$(get_color surface_tint)")

    regular6=$(strip_hash "$(get_color outline_variant)")
    bright6=$(strip_hash "$(get_color outline)")

    regular7=$(strip_hash "$(get_color on_surface_variant)")
    bright7=$(strip_hash "$(get_color on_surface)")

    mkdir -p "$HOME/.config/foot"
    cat > "$HOME/.config/foot/theme.ini" <<EOF
[colors]
foreground=$foreground
background=$background

regular0=$regular0
regular1=$regular1
regular2=$regular2
regular3=$regular3
regular4=$regular4
regular5=$regular5
regular6=$regular6
regular7=$regular7

bright0=$bright0
bright1=$bright1
bright2=$bright2
bright3=$bright3
bright4=$bright4
bright5=$bright5
bright6=$bright6
bright7=$bright7
EOF

    echo "walltheme: wallpaper set + DMS theme generated + wrote ~/.config/foot/theme.ini" >&2
    echo "walltheme: note: existing foot windows won't live-reload colors; open a new one to see changes" >&2
  '';

in
{
  home.packages = [
    pkgs.swww
    pkgs.matugen
    walltheme
  ];

  systemd.user.services.swww = {
    Unit = {
      Description = "swww wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "on-failure";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
