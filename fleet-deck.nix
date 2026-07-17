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
{ pkgs, ... }:
{
  systemd.user.services.fleet-deck = {
    description = "fleet-deck daemon (persistent Claude sessions + fleet board)";
    wantedBy = [ "default.target" ];
    path = [ pkgs.nix ];

    environment = {
      PATH = pkgs.lib.mkForce "/run/current-system/sw/bin:/run/wrappers/bin";
    };

    serviceConfig = {
      WorkingDirectory = "/home/kalin/fleet-deck";
      ExecStart = "/run/current-system/sw/bin/nix develop /home/kalin/fleet-deck -c node src/server.js";
      # Killing the daemon kills every Claude session it owns — only restart
      # on real failure, never as part of a routine stop.
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
