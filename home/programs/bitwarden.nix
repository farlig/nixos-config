{ config, pkgs, lib, ... }:

{
  home.packages = [
    pkgs.bitwarden-desktop
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentityAgent = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
      };
    };
  };
}
