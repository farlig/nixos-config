{ pkgs, ... }:

# antonixos — the desktop. Everything here is specific to this machine;
# shared configuration lives in ../../modules/nixos.
{
  imports = [
    ../../modules/nixos
    ./hardware-configuration.nix
    ./wooting.nix
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
    sbctl
  ];

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
}
