{ config, pkgs, ... }:

# Bitwarden on xps13 via Flatpak instead of the nixpkgs build. The Flatpak's
# biometric unlock (fingerprint, via polkit + the secret service) works, whereas
# the nixpkgs build panics setting up biometrics — "setKeyForUser failed: Panic
# in async function" on a null clientKeyPartB64 (upstream bitwarden/clients#15790).
# Declared with nix-flatpak, which is imported for this host only in
# home/default.nix; it needs services.flatpak.enable at the system level
# (hosts/xps13/default.nix), which also registers the polkit unlock action.
# Autostart is handled by niri (config-xps13.kdl).
let
  # Bitwarden's SSH agent socket. The flatpak default (~/.bitwarden-ssh-agent.sock,
  # i.e. inside the sandbox) is not reachable from the host, so pin it — via the
  # BITWARDEN_SSH_AUTH_SOCK override below — into the app's own data dir, which is
  # writable by the sandbox and visible to the host at the very same path.
  sshSock = "${config.home.homeDirectory}/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock";

  # Browser-integration bridge (Firefox extension biometric unlock). The Flatpak
  # starts the app's IPC socket but does not write the native-messaging *manifest*
  # a host browser needs, and its `desktop_proxy` bridge binary lives inside the
  # sandbox. So: provide the manifest ourselves, pointing at a wrapper that runs
  # that proxy *inside* the flatpak (where it connects to the app over the cache
  # socket). Needs the polkit action from hosts/xps13/default.nix to actually
  # authenticate. Firefox extension id is Bitwarden's AMO id.
  bwProxy = pkgs.writeShellScript "bitwarden-flatpak-proxy" ''
    exec ${pkgs.flatpak}/bin/flatpak run --command=/app/Bitwarden/desktop_proxy com.bitwarden.desktop "$@"
  '';
  nmManifest = builtins.toJSON {
    name = "com.8bit.bitwarden";
    description = "Bitwarden desktop <-> browser bridge (flatpak)";
    path = "${bwProxy}";
    type = "stdio";
    allowed_extensions = [ "{446900e4-71c2-419f-a6a7-df9c091e268b}" ];
  };
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

  # Despite keeping its profile in the XDG dir (~/.config/mozilla/firefox), this
  # Firefox (nixpkgs, MOZ_LEGACY_PROFILES=1) reads per-user native-messaging
  # manifests from the legacy ~/.mozilla/native-messaging-hosts. Creating
  # ~/.mozilla here does not relocate the profile (no ~/.mozilla/firefox appears).
  home.file.".mozilla/native-messaging-hosts/com.8bit.bitwarden.json".text = nmManifest;
}
