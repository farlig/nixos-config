{ pkgs, inputs, ... }:

# System-wide packages available on every host (was
# modules/configuration/common-packages.nix).
{
  # Graphical askpass helper so `sudo -A` can prompt via a dialog when there is
  # no interactive TTY (e.g. commands run by agents). Qt-based, works on niri.
  environment.sessionVariables.SUDO_ASKPASS =
    "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

  environment.systemPackages = with pkgs; [
    vim
    git
    kitty
    btop
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    equibop
    firefox
    # bitwarden-desktop is installed per-host from home/programs/bitwarden.nix
    # (nixpkgs build) or, on xps13, as a Flatpak via bitwarden-flatpak.nix.
    yazi
    mpv
    swaybg
    ffmpeg
    fastfetch
    obsidian
    polkit
    bat
    lsd
    spotify
    curl
    grim
    satty
    slurp
    wl-clipboard
    zsh
    alsa-utils
    obs-studio
    v4l-utils
    xwayland
    xwayland-satellite
    kdePackages.breeze
    proton-vpn
    claude-code
    mcp-nixos
    playerctl
    brightnessctl
    unzip
    p7zip
    kdePackages.ksshaskpass
  ];
}
