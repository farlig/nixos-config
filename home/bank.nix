{ lazyvim, ... }:

# Lean home-manager profile for the headless `bank` server. Unlike the desktop
# home/default.nix (niri, noctalia, stylix, kitty, bitwarden, fastfetch, …),
# this pulls in just a shell, an editor and a file manager. nvim.nix and
# yazi.nix are reused verbatim from the desktop set so they track future edits;
# zsh is the lean headless variant.
{
  imports = [
    ./programs/zsh-headless.nix
    ./programs/nvim.nix
    ./programs/yazi.nix
    lazyvim.homeManagerModules.default
  ];

  home.username = "anton";
  home.homeDirectory = "/home/anton";
  home.stateVersion = "26.05";
}
