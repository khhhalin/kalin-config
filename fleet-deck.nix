# fleet-deck daemon (~/fleet-deck) as a systemd *user* service, so the Claude
# PTY sessions it owns live independently of any terminal or browser — same
# rationale as kalin-tmux.nix for tmux. Runs through `nix develop` on the
# project's own flake so the daemon always uses the node/node-pty build it was
# installed with, not this flake's nixpkgs (native-addon ABI must match).
#
# `claude` and `git` come from /run/current-system/sw/bin via PATH below.
# The supervised project is hardcoded here for now; change --project (and
# `systemctl --user restart fleet-deck`) to point it elsewhere.
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
      ExecStart = "/run/current-system/sw/bin/nix develop /home/kalin/fleet-deck -c node src/server.js --project /home/kalin/environment/kalin-wm";
      # Killing the daemon kills every Claude session it owns — only restart
      # on real failure, never as part of a routine stop.
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
