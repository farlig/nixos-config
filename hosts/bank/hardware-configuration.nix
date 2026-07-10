{ lib, modulesPath, ... }:

# ⚠️  PLACEHOLDER — this file is machine-specific and must be regenerated ON THE
# BOX during install:
#
#     nixos-generate-config --root /mnt
#
# then replace this file with the generated
# /mnt/etc/nixos/hardware-configuration.nix. The values below only exist so the
# flake evaluates (`nix eval .#nixosConfigurations.bank...`) before the hardware
# is known. The real file will carry the correct NVMe UUIDs, NIC modules, etc.
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Plain ext4 root + ESP on the NVMe (nvme0n1). Labels are placeholders; the
  # generated file will use real UUIDs.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
