# fleet-deck daemon (~/fleet-deck) as a systemd *user* service, so the Claude
# PTY sessions it owns live independently of any terminal or browser — same
# rationale as kalin-tmux.nix for tmux. Runs through `nix develop` on the
# project's own flake so the daemon always uses the node/node-pty build it was
# installed with, not this flake's nixpkgs (native-addon ABI must match).
#
# `claude` and `git` come from /run/current-system/sw/bin via PATH below
# (kimi lives at ~/.kimi-code/bin/kimi, referenced absolutely by the app).
# Supervised projects come from ~/fleet-deck/config/keepers.json — edit that
# (hot-reloaded) rather than this unit to add/remove projects.
{ pkgs, meta, ... }:
{
  systemd.user.services.fleet-deck = {
    description = "fleet-deck daemon (persistent Claude sessions + fleet board)";
    wantedBy = [ "default.target" ];
    path = [ pkgs.nix ];

    # A rebuild switch must never take the fleet down: restarting this unit
    # kills every live agent PTY. Restart manually (systemctl --user restart
    # fleet-deck) when the daemon code actually changed.
    restartIfChanged = false;

    environment = {
      PATH = pkgs.lib.mkForce "/run/current-system/sw/bin:/run/wrappers/bin";
    };

    serviceConfig = {
      WorkingDirectory = meta.dirs.fleetDeck;
      ExecStart = "/run/current-system/sw/bin/nix develop ${meta.dirs.fleetDeck} -c node src/server.js";
      # Killing the daemon kills every Claude session it owns — only restart
      # on real failure, never as part of a routine stop.
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
