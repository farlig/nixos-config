{ config, pkgs, lazyvim, hostName, ... }:

{
  imports = [
    # programs
    ./programs/niri/niri.nix
    ./programs/nvim.nix
    # ./programs/bash.nix
    ./programs/zsh.nix
    ./programs/kitty.nix
    ./programs/yazi.nix
    ./programs/bitwarden.nix
    ./programs/noctalia.nix
    ./programs/stylix.nix
    ../modules/termfilechooser.nix
    lazyvim.homeManagerModules.default
  ];
  
  home.username = "anton";
  home.homeDirectory = "/home/anton";
  home.stateVersion = "26.05";
  home.packages = [
    pkgs.wl-clipboard
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    download = "${config.home.homeDirectory}/downloads";
    videos = "${config.home.homeDirectory}/videos";
    pictures = "${config.home.homeDirectory}/pictures";
    documents = "${config.home.homeDirectory}/documents";
    projects = "${config.home.homeDirectory}/projects";
  };
}
