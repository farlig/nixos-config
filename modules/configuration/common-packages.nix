{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
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
    opensnitch-ui
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
  ];
}
