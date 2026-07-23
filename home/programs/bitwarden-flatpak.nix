{ config, ... }:

# Bitwarden on xps13 via Flatpak instead of the nixpkgs build. The Flatpak's
# biometric unlock (fingerprint, via polkit + the secret service) works, whereas
# the nixpkgs build panics setting up biometrics — "setKeyForUser failed: Panic
# in async function" on a null clientKeyPartB64 (upstream bitwarden/clients#15790).
# Declared with nix-flatpak, which is imported for this host only in
# home/default.nix; it needs services.flatpak.enable at the system level
# (hosts/xps13/default.nix). Autostart is handled by niri (config-xps13.kdl).
let
  # Bitwarden's SSH agent socket. The flatpak default (~/.bitwarden-ssh-agent.sock,
  # i.e. inside the sandbox) is not reachable from the host, so pin it — via the
  # BITWARDEN_SSH_AUTH_SOCK override below — into the app's own data dir, which is
  # writable by the sandbox and visible to the host at the very same path.
  sshSock = "${config.home.homeDirectory}/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock";
in
{
  services.flatpak = {
    packages = [ "com.bitwarden.desktop" ];
    overrides.settings."com.bitwarden.desktop".Environment.BITWARDEN_SSH_AUTH_SOCK = sshSock;
  };

  home.sessionVariables.SSH_AUTH_SOCK = sshSock;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentityAgent = sshSock;
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
      };
    };
  };
}
