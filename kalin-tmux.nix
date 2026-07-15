# Persistent tmux server as a login-scoped systemd *user* service, so terminal
# sessions live independently of kalin-wm and of any foot window: a compositor
# restart detaches clients but never kills the server or its sessions. This
# only *guarantees* the server + the base "kalin-apps" session exist at login —
# kalin-wm's spawn() still bootstraps "kalin-apps" in run() as a fallback, and
# the actual per-terminal sessions are created on demand by `kalin-term`.
#
# Deliberately non-destructive: `has-session || new-session` never clobbers a
# running server, and there is no `kill-server` on stop, so a rebuild/restart of
# this unit can't take down live sessions (e.g. the Claude Code session). The
# server is torn down only when the whole systemd user manager exits at logout.
{ pkgs, ... }:
{
  systemd.user.services.kalin-tmux = {
    description = "Persistent tmux server (compositor-independent session backbone)";
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '${pkgs.tmux}/bin/tmux has-session -t kalin-apps 2>/dev/null || ${pkgs.tmux}/bin/tmux new-session -d -s kalin-apps'
      '';
    };
  };
}
