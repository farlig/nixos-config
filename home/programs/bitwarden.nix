{ config, pkgs, lib, ... }:

{
  home.packages = [
    pkgs.bitwarden-desktop
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
  };

  # Autostart, declared here rather than via the app's own "start automatically
  # on login" setting: that setting writes this file itself with the *current*
  # store path baked into Exec=, so it keeps launching the old build after every
  # package update (silently — both versions coexist in the store) until the
  # path is finally GC'd and it breaks. Keep the in-app setting OFF; this entry
  # is regenerated against the current package on each rebuild.
  home.file.".config/autostart/bitwarden.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Bitwarden
    Comment=Bitwarden startup script
    Exec=${lib.getExe pkgs.bitwarden-desktop} --autostart
    StartupNotify=false
    Terminal=false
  '';

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
