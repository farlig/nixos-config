{ pkgs, inputs, ... }:

# System-wide packages available on every host (was
# modules/configuration/common-packages.nix).
{
  environment.systemPackages = with pkgs; [
    vim
    git
    kitty
    btop
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    equibop
    firefox
    bitwarden-desktop
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
    unzip
    p7zip
  ];
}
