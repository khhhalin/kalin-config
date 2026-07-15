# Web-viewable terminal (ttyd) into a persistent tmux session running Claude Code.
# Localhost-only — reach it via SSH port-forward (ssh -L 7681:localhost:7681 <host>)
# or a browser on this machine at http://127.0.0.1:7681.
#
# ttyd spawns the tmux command per browser connection; tmux's own server keeps
# the "claude" session alive independently, so reconnecting (or opening a
# second tab) re-attaches to the same running session instead of starting a
# new one.
{ pkgs, meta, ... }:

let
  # `claude -c` resumes the most recent conversation for the current working
  # directory, which is why WorkingDirectory below is pinned to a fixed path
  # (claude keys conversation history by cwd). Falls back to a fresh `claude`
  # if there's no prior conversation yet (e.g. first boot), and falls back to
  # an interactive shell if claude exits, so the tmux session doesn't die
  # under ttyd just because claude quit.
  claudeShellCmd = ''${pkgs.zsh}/bin/zsh -l -c "claude -c || claude; exec ${pkgs.zsh}/bin/zsh -l"'';
in
{
  environment.systemPackages = [ pkgs.ttyd ];

  systemd.services.claude-tty = {
    description = "ttyd web terminal into a tmux session running Claude Code";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    # ttyd's libwebsockets dlopen's its evlib_uv plugin at runtime rather than
    # linking it, so it needs the plugin's containing dir on the loader path.
    environment.LD_LIBRARY_PATH = "${pkgs.libwebsockets}/lib";

    serviceConfig = {
      Type = "simple";
      User = meta.userName;
      WorkingDirectory = "/home/${meta.userName}";
      ExecStart = ''
        ${pkgs.ttyd}/bin/ttyd -i lo -p 7681 -W \
          ${pkgs.tmux}/bin/tmux -u new-session -A -s claude '${claudeShellCmd}'
      '';
      Restart = "on-failure";
    };
  };
}
