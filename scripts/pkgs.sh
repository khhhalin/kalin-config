#!/usr/bin/env bash
# pkgs — browse which packages are installed on which system (host + every
# distrobox container). No args: fzf TUI. Also: `pkgs list [system]`,
# `pkgs which <q>`. Containers are auto-detected; package manager is detected
# per container, so any distro works.
set -euo pipefail

# Names of all existing distrobox containers.
container_names() {
  distrobox list --no-color 2>/dev/null \
    | awk -F'|' 'NR>1 {gsub(/^ +| +$/,"",$2); if ($2!="") print $2}'
}

# Run a command inside a container; no-op if it doesn't exist.
# distrobox-enter auto-starts it; banners go to stderr.
in_ctr() {
  local name="$1" cmd="$2"
  podman container exists "$name" 2>/dev/null || return 0
  distrobox-enter -n "$name" -- sh -c "$cmd" 2>/dev/null || true
}

# Snippet (run inside a container) that prints user-installed package names,
# picking the right package manager.
GENLIST='
if command -v pacman >/dev/null 2>&1; then pacman -Qqe
elif command -v apt-mark >/dev/null 2>&1; then apt-mark showmanual
elif command -v dnf >/dev/null 2>&1; then dnf repoquery --userinstalled --qf "%{name}\n" 2>/dev/null || rpm -qa --qf "%{NAME}\n"
elif command -v rpm >/dev/null 2>&1; then rpm -qa --qf "%{NAME}\n"
elif command -v apk >/dev/null 2>&1; then apk info
else echo "(unknown package manager)"; fi'

# One package name per line for a given system.
list_system() {
  if [ "$1" = host ]; then
    # Direct references of the system env ≈ the packages it was built from.
    nix-store -q --references /run/current-system/sw 2>/dev/null \
      | sed -E 's#^/nix/store/[a-z0-9]+-##; s/-[0-9].*$//' \
      | sort -u
  else
    in_ctr "$1" "$GENLIST"
  fi
}

# Every "<system>\t<package>" pair across host + all containers.
build_index() {
  for sys in host $(container_names); do
    list_system "$sys" | while IFS= read -r p; do
      [ -n "$p" ] && printf '%s\t%s\n' "$sys" "$p"
    done
  done
}

# Detailed info for one package (used by the fzf preview).
preview() {
  local sys="$1" pkg="$2"
  if [ "$sys" = host ]; then
    printf 'host package: %s\n\n' "$pkg"
    nix-store -q --references /run/current-system/sw 2>/dev/null \
      | grep -E -- "-${pkg}(-[0-9]|$)" | head
  else
    in_ctr "$sys" "
      if command -v pacman >/dev/null 2>&1; then pacman -Qi '$pkg'
      elif command -v dpkg >/dev/null 2>&1; then dpkg -s '$pkg' 2>/dev/null || apt show '$pkg' 2>/dev/null
      elif command -v rpm >/dev/null 2>&1; then rpm -qi '$pkg'
      elif command -v apk >/dev/null 2>&1; then apk info -a '$pkg'
      fi"
  fi
}

case "${1:-tui}" in
  --preview) preview "$2" "$3" ;;
  list)
    if [ "$#" -gt 1 ]; then list_system "$2"; else build_index; fi ;;
  which)
    [ "$#" -ge 2 ] || { echo "usage: pkgs which <query>" >&2; exit 2; }
    build_index | awk -v q="$2" 'index(tolower($2), tolower(q))' \
      | column -t -s "$(printf '\t')" ;;
  tui|"")
    build_index | fzf --delimiter='\t' --with-nth=1,2 \
      --preview 'pkgs --preview {1} {2}' --preview-window=right,60%,wrap \
      --header 'packages by system — type to filter · esc quits' \
      --prompt 'pkg> ' ;;
  -h|--help)
    sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) echo "pkgs: unknown command '$1' (try: list, which, or no args)" >&2; exit 2 ;;
esac
