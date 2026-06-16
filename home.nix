{ config, pkgs, lazyvim, ... }:

{
  imports = [
    ./programs/niri/niri.nix
    ./programs/nvim.nix
    # ./programs/bash.nix
    ./programs/zsh.nix
    ./programs/kitty.nix
    ./programs/yazi.nix
    ./modules/termfilechooser.nix
    lazyvim.homeManagerModules.default
  ];
  
  home.username = "anton";
  home.homeDirectory = "/home/anton";
  home.stateVersion = "26.05";
  home.packages = [
    pkgs.wl-clipboard
  ];
}
