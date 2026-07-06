{ ... }:

# Shared boot behaviour: quiet/splash boot and EFI variable access.
# The bootloader itself (limine vs systemd-boot) and the kernel package are
# machine-specific and stay in the host file.
{
  boot.loader.efi.canTouchEfiVariables = true;

  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  # Quiet, graphical boot (was modules/configuration/quietboot.nix)
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "vt.global_cursor_default=0"
  ];
  boot.plymouth.enable = true;
}
