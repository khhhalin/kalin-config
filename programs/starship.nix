{ ... }:

{
  programs.starship = {
    enable = true;

    # Shell integration (you use zsh in `programs/zsh.nix`).
    enableZshIntegration = true;

    # Config is generated as ~/.config/starship.toml.
    #
    # Uncomment and customize any of the below to get started.
    # The schema is documented upstream: https://starship.rs/config/
    #
    # settings = {
    #   add_newline = false;
    #
    #   # Example: keep the prompt compact.
    #   format = "$directory$git_branch$git_status$character";
    #
    #   directory = {
    #     truncation_length = 3;
    #     truncate_to_repo = true;
    #   };
    #
    #   git_branch = {
    #     symbol = " ";
    #   };
    #
    #   character = {
    #     success_symbol = "[➜](bold green)";
    #     error_symbol = "[➜](bold red)";
    #   };
    # };
  };
}
