{ pkgs, inputs, ... }:

# System-wide packages for the desktop hosts. Pulled in by the desktop bundle,
# so the headless server never sees these.
let
  # The XPS 13 webcam is an Intel IPU6 (ov01a10). Its raw /dev/video* nodes only
  # emit Bayer data, so apps that open V4L2 directly (Discord/Equibop) get no
  # image — the usable camera exists only via libcamera→PipeWire. Harmless on
  # hosts with a normal UVC webcam (PipeWire fronts those too).
  #   WebRtcPipeWireCamera        requests the camera via the portal
  #   LIBCAMERA_SOFTISP_MODE=cpu  CPU debayer; GPU (EGL) produces DMA-BUF
  #                               strides Chromium rejects
  #
  # Chromium's bundled ffmpeg has no HEVC decoder, so H.265 video only plays
  # through VA-API hardware decode:
  #   LD_LIBRARY_PATH += libva    Electron's rpath has no libva to dlopen
  #   Vaapi*/…HEVC… features      enable VA-API decode; VaapiOnNvidiaGPUs stops
  #                               Chromium skipping the nvidia-drm device
  #
  # Chromium only honours the last --enable-features, so all features share
  # the one flag.
  equibop = pkgs.symlinkJoin {
    name = "equibop";
    paths = [ pkgs.equibop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/equibop \
        --add-flags "--enable-features=WebRtcPipeWireCamera,VaapiVideoDecoder,VaapiOnNvidiaGPUs,PlatformHEVCDecoderSupport,AcceleratedVideoDecodeLinuxGL" \
        --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.libva ]} \
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
    inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
    # bitwarden-desktop is installed per-host from home/programs/bitwarden.nix
    # (nixpkgs build) or, on xps13, as a Flatpak via bitwarden-flatpak.nix.
    # The CLI has no such split, so it lives here for both desktop hosts.
    bitwarden-cli
    yazi
    mpv
    swaybg
    ffmpeg
    fastfetch
    obsidian
    krita
    polkit
    bat
    eza
    tldr
    spotify
    inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Music/video downloaders. yt-dlp for ad-hoc grabs + format inspection
    # (`yt-dlp -F`); spotdl wraps it to tag downloads with Spotify metadata +
    # cover art. Both use ffmpeg (above) as their postprocessor. Also on bank,
    # where the music library lives and the bulk downloads run — see
    # hosts/bank/default.nix.
    yt-dlp
    spotdl
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
    python3
    fzf
    unzip
    p7zip
    kdePackages.ksshaskpass
  ];
}
