{ config, pkgs, ... }:

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
    prismlauncher # modded Minecraft launcher (imports CurseForge/Modrinth packs)
    sbctl
  ];

  # Bluetooth (controllers, headphones). upower stays laptop-only.
  hardware.bluetooth.enable = true;

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
  # re-init before it can render. That delay is what made "the first kitty when
  # none is already open" feel slow (fastfetch itself runs in ~50ms).
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
