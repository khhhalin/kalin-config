#!/usr/bin/env bash
set -euo pipefail

NAME=""
IMAGE=""
DISTRO=""
SCRIPT_NAME="$(basename "$0")"
HOST_USER="$(id -un)"

usage() {
  cat <<'EOF'
Usage:
  debian|ubuntu|fedora|arch install <file.deb>
                           Install the .deb into the named distro container
  debian|ubuntu|fedora|arch enter
                           Enter the named distro container shell
  debian|ubuntu|fedora|arch run <cmd...>
                           Run a command inside the named distro container
  debian|ubuntu|fedora|arch pkg install <pkg...>
                           Install distro packages inside the container
  debian|ubuntu|fedora|arch help
                           Show this help

Call via the distro-named binary (e.g., "debian enter") or by prefixing the
distro as the first argument (e.g., "distro-helper debian enter").
EOF
}
case "$SCRIPT_NAME" in
  debian|ubuntu|fedora|arch)
    DISTRO="$SCRIPT_NAME"
    ;;
esac

if [ -z "$DISTRO" ]; then
  case "${1:-}" in
    debian|ubuntu|fedora|arch)
      DISTRO="$1"
      shift
      ;;
    help|-h|--help)
      usage
      exit 0
      ;;
  esac
fi

if [ -z "$DISTRO" ]; then
  usage
  exit 2
fi

case "$DISTRO" in
  debian)
    IMAGE="debian:stable"
    NAME="debian"
    ;;
  ubuntu)
    IMAGE="ubuntu:24.04"
    NAME="ubuntu"
    ;;
  fedora)
    IMAGE="registry.fedoraproject.org/fedora:latest"
    NAME="fedora"
    ;;
  arch)
    IMAGE="docker.io/library/archlinux:latest"
    NAME="arch"
    ;;
  *)
    echo "[distro] unsupported distro: $DISTRO" >&2
    exit 2
    ;;
esac

if [ "$#" -lt 1 ]; then
  usage
  exit 2
fi

ensure_container() {
  if podman container exists "$NAME" 2>/dev/null; then
    return 0
  fi

  echo "[distro] creating '$NAME' from '$IMAGE'..."
  distrobox-create \
    --name "$NAME" \
    --image "$IMAGE" \
    --yes \
    --additional-packages "sudo ca-certificates" >/dev/null

  # Allow passwordless sudo for the host user inside the container so
  # installs don't prompt for a container password.
  distrobox-enter -n "$NAME" -- sudo sh -c "echo '$HOST_USER ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/distro-helper && chmod 440 /etc/sudoers.d/distro-helper"
}

enter_sh() {
  ensure_container
  exec distrobox-enter -n "$NAME"
}

run_in_container() {
  ensure_container
  distrobox-enter -n "$NAME" -- "$@"
}

# Convert a file:// URL or URL-escaped path to a normal path.
normalize_path() {
  python3 - <<'PY' "$1"
import sys
import urllib.parse
p = sys.argv[1]
if p.startswith('file://'):
    p = p[7:]
print(urllib.parse.unquote(p))
PY
}

install_deb() {
  local input="$1"
  local path
  path="$(normalize_path "$input")"

  if [ ! -e "$path" ]; then
    echo "[distro] file not found: $path" >&2
    exit 2
  fi

  local workdir="$HOME/.local/share/distrobox-helper"
  mkdir -p "$workdir"

  local staged="$workdir/$(basename "$path")"
  cp -f "$path" "$staged"

  echo "[distro] installing: $staged"

  # Run install + export + launch logic inside the container.
  run_in_container sh -lc '
    set -e
    deb="$1"

    if ! command -v sudo >/dev/null 2>&1; then
      echo "[distro] sudo missing in container; cannot install" >&2
      exit 3
    fi

    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -y >/dev/null 2>&1 || sudo apt-get update >/dev/null
      sudo apt-get install -y "$deb"
    else
      echo "[distro] non-Debian/Ubuntu base image detected; apt-get unavailable" >&2
      echo "[distro] use debian|ubuntu (or provide a deb-compatible image)" >&2
      exit 4
    fi

    pkg="$(dpkg-deb -f "$deb" Package 2>/dev/null || true)"
    if [ -z "$pkg" ]; then
      echo "[distro] installed, but could not read Package name from .deb" >&2
      exit 0
    fi

    desktops="$(dpkg -L "$pkg" 2>/dev/null | grep -E "\\.desktop$" || true)"
    if [ -z "$desktops" ]; then
      echo "[distro] installed $pkg; no .desktop files to export"
      exit 0
    fi

    first_desktop="$(printf "%s\n" "$desktops" | head -n1)"
    echo "[distro] exporting desktop entries for $pkg:"
    printf "%s\n" "$desktops" | while IFS= read -r df; do
      [ -n "$df" ] || continue
      echo "  - $df"
      distrobox-export --app "$df" --export-label none >/dev/null 2>&1 || true
    done

    exec_line="$(grep -m1 "^Exec=" "$first_desktop" 2>/dev/null | cut -d= -f2- || true)"
    if [ -z "$exec_line" ]; then
      echo "[distro] exported apps; launch manually from your app launcher"
      exit 0
    fi

    # Strip common desktop placeholders (%U, %F, etc.)
    clean_exec="$(printf "%s" "$exec_line" | sed -E "s/[[:space:]]*%[fFuUdDnNickvm]//g")"

    echo "[distro] launching: $clean_exec"
    sh -lc "$clean_exec" || true
  ' sh "$staged"

  echo "[distro] done. If the app exported, it should appear in your launcher."
}
pkg_action() {
  local action="$1"
  shift

  case "$action" in
    install)
      if [ "$#" -eq 0 ]; then
        echo "[distro] missing packages to install" >&2
        exit 2
      fi
      case "$DISTRO" in
        debian|ubuntu)
          run_in_container sudo apt-get update -y >/dev/null 2>&1 || run_in_container sudo apt-get update >/dev/null
          run_in_container sudo apt-get install -y "$@"
          ;;
        fedora)
          run_in_container sudo dnf install -y "$@"
          ;;
        arch)
          run_in_container sudo pacman -Sy --noconfirm "$@"
          ;;
      esac
      ;;
    *)
      echo "[distro] unsupported pkg action: $action" >&2
      exit 2
      ;;
  esac
}

cmd="${1:-help}"
case "$cmd" in
  help|-h|--help)
    usage
    ;;
  enter)
    enter_sh
    ;;
  run)
    shift
    if [ "$#" -eq 0 ]; then
      echo "[distro] missing command" >&2
      exit 2
    fi
    run_in_container "$@"
    ;;
  install)
    shift
    if [ "$#" -eq 0 ]; then
      echo "[distro] missing .deb path" >&2
      exit 2
    fi
    install_deb "$1"
    ;;
  pkg)
    shift
    if [ "$#" -eq 0 ]; then
      echo "[distro] missing pkg subcommand" >&2
      exit 2
    fi
    pkg_action "$1" "${@:2}"
    ;;
  *)
    usage
    exit 2
    ;;
 esac
