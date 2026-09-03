{ config, pkgs, ... }:

# antonixos — the desktop. Everything here is specific to this machine;
# shared configuration lives in ../../modules/nixos.
{
  imports = [
    ../../modules/nixos
    ./hardware-configuration.nix
    ./udev.nix
  ];

  networking.hostName = "antonixos";

  # Bootloader: Limine with secure boot and a Windows entry.
  boot.loader.limine = {
    enable = true;
    secureBoot.enable = true;
    # Cap boot-menu generations so the ESP can't fill up.
    maxGenerations = 10;
    extraEntries = ''
      /Windows
        protocol: efi
        path: uuid(98ecdeb2-5ef3-42e4-93f8-57693c8a2894):/EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };
  boot.loader.timeout = 3;

  # CachyOS kernel.
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Keyboard layout for this machine (console keymap is shared in locale.nix).
  services.xserver.xkb = {
    layout = "eu";
    variant = "";
  };

  # Desktop-only packages (gaming / secure-boot tooling).
  environment.systemPackages = with pkgs; [
    protontricks
    winetricks
    protonup-qt
    deadlock-mod-manager
    prismlauncher # modded Minecraft launcher (imports CurseForge/Modrinth packs)
    nyaa # TUI for browsing/downloading torrents from nyaa.si
    sbctl
    xkeyboard_config # XKB layout data at a stable path, for foreign binaries
    desktop-file-utils # update-desktop-database, which desktop apps shell out to
  ];

  # Expose share/X11 (XKB layout data) on the system path.
  environment.pathsToLink = [ "/share/X11" ];

  # Bluetooth (controllers, headphones). upower stays laptop-only.
  hardware.bluetooth.enable = true;

  # Flatpak — for the Twintail Launcher (anime-game launcher) from Flathub, which
  # isn't packaged in nixpkgs. The app and its flathub remote are declared via
  # nix-flatpak in home/programs/twintail.nix (imported for antonixos in
  # home/default.nix).
  services.flatpak.enable = true;

  # Loader and library set for unpatched foreign binaries (AppImages, vendor
  # blobs), which run as ordinary processes rather than in an FHS sandbox.
  #
  # The list is long because bundlers deliberately ship none of the libraries
  # they expect every distro to have — the C++ runtime, X11, GL/GBM/Vulkan, xkb,
  # fontconfig, the glib/GTK stack — so the host supplies those plus everything
  # they pull in transitively (fribidi, gnutls, gmp, …). nix-ld's own default
  # covers systemd and nix only, which is enough for CLI tools and nothing else.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib glib gtk3 cairo pango gdk-pixbuf harfbuzz atk
      at-spi2-core at-spi2-atk dbus systemdLibs util-linux
      fontconfig freetype expat libxml2 libsecret nss nspr sqlite icu
      libdrm mesa libgbm libGL libglvnd libGLU vulkan-loader libepoxy libva
      pipewire libxkbcommon wayland alsa-lib libpulseaudio openssl curl zlib
      libgcrypt libgpg-error fribidi libthai libdatrie libselinux pcre2 libffi
      graphite2 brotli zstd xz bzip2 libjpeg libpng libwebp libtiff libnotify
      gnutls libtasn1 p11-kit nghttp2 libpsl libidn2 libunistring krb5 keyutils
      gmp nettle e2fsprogs libcap
      libX11 libXext libXrender libXrandr libXi
      libXcursor libXfixes libXtst libxcb libXScrnSaver
      libXcomposite libXdamage libxshmfence
    ];
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    gamescopeSession.enable = true;
  };

  # NVIDIA (CachyOS build).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = pkgs.nvidia_cachyos;
  };

  # Keep the driver's device state resident even with no GPU clients. Without
  # this, when the last GL/EGL client (e.g. the last kitty window) exits, the
  # driver tears down and the card idles; the next client pays a ~1-2s cold
  # re-init before it can render, which shows up as a slow first launch of any
  # GPU-using app once nothing else is holding the driver open.
  #
  # The stock `hardware.nvidia.nvidiaPersistenced` option is unbuildable on the
  # cachyos driver (upstream re-uploaded the persistenced source, breaking its
  # fixed-output hash), so enable persistence mode via nvidia-smi instead — it
  # ships with the already-built driver package.
  systemd.services.nvidia-persistence-mode = {
    description = "Enable NVIDIA persistence mode (keep the GPU warm to avoid cold re-init)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pm 1";
      ExecStop = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pm 0";
    };
  };
}
