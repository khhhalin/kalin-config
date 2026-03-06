#!/usr/bin/env bash
set -euo pipefail

NAME="${DEBBOX_NAME:-debbox}"
IMAGE="${DEBBOX_IMAGE:-debian:stable}"
DISTRO=""
name_custom=0
HOST_USER="$(id -un)"

[ -n "${DEBBOX_NAME-}" ] && name_custom=1

usage() {
  cat <<'EOF'
Usage:
  debbox [--distro D] [--image IMG] [--name N] <file.deb>
                         Install the .deb into the container and try to export+launch apps
  debbox [--distro D] [--image IMG] [--name N] enter
                         Enter the container shell
  debbox [--distro D] [--image IMG] [--name N] run <cmd...>
                         Run a command inside the container
  debbox help             Show this help

Options:
  --distro D   One of: debian (default), ubuntu, fedora, arch
  --image IMG  Override container image (e.g. ubuntu:24.04)
  --name N     Container name override (default debbox or debbox-<distro>)

Environment:
  DEBBOX_NAME   Container name
  DEBBOX_IMAGE  OCI image
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --distro)
      DISTRO="${2:-}"
      shift 2
      ;;
    --image)
      IMAGE="${2:-}"
      shift 2
      ;;
    --name)
      NAME="${2:-}"
      name_custom=1
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

if [ -n "$DISTRO" ]; then
  case "$DISTRO" in
    debian)
      IMAGE="debian:stable"
      [ "$name_custom" -eq 0 ] && NAME="debbox-debian"
      ;;
    ubuntu)
      IMAGE="ubuntu:24.04"
      [ "$name_custom" -eq 0 ] && NAME="debbox-ubuntu"
      ;;
    fedora)
      IMAGE="registry.fedoraproject.org/fedora:latest"
      [ "$name_custom" -eq 0 ] && NAME="debbox-fedora"
      ;;
    arch)
      IMAGE="docker.io/library/archlinux:latest"
      [ "$name_custom" -eq 0 ] && NAME="debbox-arch"
      ;;
    *)
      echo "[debbox] unsupported distro: $DISTRO" >&2
      exit 2
      ;;
  esac
fi

ensure_container() {
  if podman container exists "$NAME" 2>/dev/null; then
    return 0
  fi

  echo "[debbox] creating distrobox '$NAME' from '$IMAGE'..."
  distrobox-create \
    --name "$NAME" \
    --image "$IMAGE" \
    --yes \
    --additional-packages "sudo ca-certificates" >/dev/null

  # Allow passwordless sudo for the host user inside the container so
  # installs don't prompt for a container password.
  distrobox-enter -n "$NAME" -- sudo sh -c "echo '$HOST_USER ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/debbox && chmod 440 /etc/sudoers.d/debbox"
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
    echo "[debbox] file not found: $path" >&2
    exit 2
  fi

  local workdir="$HOME/.local/share/debbox"
  mkdir -p "$workdir"

  local staged="$workdir/$(basename "$path")"
  cp -f "$path" "$staged"

  echo "[debbox] installing: $staged"

  # Run install + export + launch logic inside the container.
  run_in_container sh -lc '
    set -e
    deb="$1"

    if ! command -v sudo >/dev/null 2>&1; then
      echo "[debbox] sudo missing in container; cannot install" >&2
      exit 3
    fi

    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -y >/dev/null 2>&1 || sudo apt-get update >/dev/null
      sudo apt-get install -y "$deb"
    else
      echo "[debbox] non-Debian/Ubuntu base image detected; apt-get unavailable" >&2
      echo "[debbox] set --distro debian|ubuntu (or provide a deb-compatible image)" >&2
      exit 4
    fi

    pkg="$(dpkg-deb -f "$deb" Package 2>/dev/null || true)"
    if [ -z "$pkg" ]; then
      echo "[debbox] installed, but could not read Package name from .deb" >&2
      exit 0
    fi

    desktops="$(dpkg -L "$pkg" 2>/dev/null | grep -E "\\.desktop$" || true)"
    if [ -z "$desktops" ]; then
      echo "[debbox] installed $pkg; no .desktop files to export"
      exit 0
    fi

    first_desktop="$(printf "%s\n" "$desktops" | head -n1)"
    echo "[debbox] exporting desktop entries for $pkg:"
    printf "%s\n" "$desktops" | while IFS= read -r df; do
      [ -n "$df" ] || continue
      echo "  - $df"
      distrobox-export --app "$df" --export-label none >/dev/null 2>&1 || true
    done

    exec_line="$(grep -m1 "^Exec=" "$first_desktop" 2>/dev/null | cut -d= -f2- || true)"
    if [ -z "$exec_line" ]; then
      echo "[debbox] exported apps; launch manually from your app launcher"
      exit 0
    fi

    # Strip common desktop placeholders (%U, %F, etc.)
    clean_exec="$(printf "%s" "$exec_line" | sed -E "s/[[:space:]]*%[fFuUdDnNickvm]//g")"

    echo "[debbox] launching: $clean_exec"
    sh -lc "$clean_exec" || true
  ' sh "$staged"

  echo "[debbox] done. If the app exported, it should appear in your launcher."
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
      echo "[debbox] missing command" >&2
      exit 2
    fi
    run_in_container "$@"
    ;;
  *.deb|file://*.deb)
    install_deb "$cmd"
    ;;
  *)
    # If invoked like: debbox /path/to/file.deb
    if [ "$#" -eq 1 ] && printf "%s" "$cmd" | grep -qiE "\.deb($|\?)"; then
      install_deb "$cmd"
    else
      usage
      exit 2
    fi
    ;;
 esac
