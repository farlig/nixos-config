{ config, pkgs, lazyvim, hostName, ... }:

# Anton's home-manager configuration (was home/common.nix). Imported by the
# system build via modules/nixos/home-manager.nix.
{
  imports = [
    ./programs/niri/niri.nix
    ./programs/nvim.nix
    ./programs/zsh.nix
    ./programs/kitty.nix
    ./programs/yazi.nix
    ./programs/fastfetch.nix
    ./programs/bitwarden.nix
    ./programs/noctalia.nix
    ./programs/stylix.nix
    ./programs/termfilechooser.nix
    lazyvim.homeManagerModules.default
  ];

  home.username = "anton";
  home.homeDirectory = "/home/anton";
  home.stateVersion = "26.05";

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    download = "${config.home.homeDirectory}/downloads";
    videos = "${config.home.homeDirectory}/videos";
    pictures = "${config.home.homeDirectory}/pictures";
    documents = "${config.home.homeDirectory}/documents";
    projects = "${config.home.homeDirectory}/projects";
  };

  # URL-scheme handlers. Equibop registers itself as the discord:// handler via
  # Electron's setAsDefaultProtocolClient, but that never sticks on NixOS, so
  # Discord invite links (discord.gg/…) opened in Firefox had nothing to hand
  # off to. Setting it here makes it reproducible on a fresh install.
  #
  # NOTE: enabling xdg.mimeApps makes ~/.config/mimeapps.list a read-only
  # symlink into the store, so apps can no longer self-register schemes at
  # runtime. The other entries below were previously written imperatively by
  # those apps (claude-cli login flow, deadlock mod manager); they're carried
  # over here so nothing regresses. Add future runtime-registered schemes here.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/discord" = "equibop.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/deadlock-mod-manager" = ".deadlock-mod-manager-wrapped-handler.desktop";
      "x-scheme-handler/deadlock-modmanager" = ".deadlock-mod-manager-wrapped-handler.desktop";
      "x-scheme-handler/dlmm" = ".deadlock-mod-manager-wrapped-handler.desktop";
    };
  };
}
