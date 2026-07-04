# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.limine.enable = true;
  boot.loader.limine.secureBoot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  networking.hostName = "antonixos"; # Define your hostname.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;

  # services.tuned.enable = true;

  services.upower.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  nix.settings = {
    trusted-users = [ "@wheel" ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "eu";
    variant = "";
  };

  # services.greetd = {
  #   enable = true;
  #   settings = {
  #     default_session = {
  #       command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
  #     };
  #   };
  # };
  #
  # systemd.services.greetd.serviceConfig = {
  #   Type = "idle";
  # };

  # Configure console keymap
  console.keyMap = "dk-latin1";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
    environment.systemPackages = with pkgs; [
    protontricks
    winetricks
    protonup-qt
    sbctl
    ];

  programs.zsh.enable = true;

  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    gamescopeSession = {
      enable = true;
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  xdg.portal = {
    extraPortals = [ 
    pkgs.xdg-desktop-portal-termfilechooser
    pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common."org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
      niri."org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    };
  };

  services.tailscale = { enable = true; };

  # nvidia driver stuff
  hardware.graphics = {
    enable = true;
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

  hardware.graphics.enable32Bit = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
