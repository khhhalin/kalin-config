# Persistent tmux server as a login-scoped systemd *user* service, so terminal
# sessions live independently of kalin-wm and of any foot window: a compositor
# restart detaches clients but never kills the server or its sessions. This
# only *guarantees* the server + the base "kalin-apps" session exist at login —
# kalin-wm's spawn() still bootstraps "kalin-apps" in run() as a fallback, and
# the actual per-terminal sessions are created on demand by `kalin-term`.
#
# Deliberately non-destructive: `has-session || new-session` never clobbers a
# running server, and there is no `kill-server` on stop. That alone is NOT
# enough: the server forked by ExecStart lands in this unit's cgroup, and the
# default KillMode=control-group meant a unit restart (e.g. nixos-rebuild
# switch after editing this file, 2026-07-21) SIGKILLed the server and every
# session in it — exactly what this service exists to prevent. KillMode=process
# makes stop/restart touch only the (already-exited) ExecStart process, so the
# server survives; it is torn down only when the systemd user manager exits at
# logout.
{ pkgs, ... }:
{
  systemd.user.services.kalin-tmux = {
    description = "Persistent tmux server (compositor-independent session backbone)";
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      KillMode = "process";
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '${pkgs.tmux}/bin/tmux has-session -t kalin-apps 2>/dev/null || ${pkgs.tmux}/bin/tmux new-session -d -s kalin-apps; ${pkgs.tmux}/bin/tmux has-session -t terminals 2>/dev/null || ${pkgs.tmux}/bin/tmux new-session -d -s terminals'
      '';
    };
  };
}
