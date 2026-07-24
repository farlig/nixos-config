{ pkgs, inputs, ... }:

# System-wide packages available on every host (was
# modules/configuration/common-packages.nix).
let
  # The XPS 13 webcam is an Intel IPU6 (ov01a10). Its raw /dev/video* nodes only
  # emit Bayer data, so apps that open V4L2 directly (Discord/Equibop) get no
  # image — the usable camera exists only via libcamera→PipeWire. These two
  # settings make Equibop's Chromium use the PipeWire camera path:
  #   --enable-features=WebRtcPipeWireCamera  requests the camera via the portal
  #   LIBCAMERA_SOFTISP_MODE=cpu              CPU debayer; GPU (EGL) produces
  #                                           DMA-BUF strides Chromium rejects
  # Harmless on hosts with a normal UVC webcam (PipeWire fronts those too).
  equibop = pkgs.symlinkJoin {
    name = "equibop";
    paths = [ pkgs.equibop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/equibop \
        --add-flags "--enable-features=WebRtcPipeWireCamera" \
        --set-default LIBCAMERA_SOFTISP_MODE cpu
    '';
  };
in
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
