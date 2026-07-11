{ ... }:

# Shared boot behaviour: EFI variable access. The bootloader itself (limine vs
# systemd-boot) and the kernel package are machine-specific and stay in the
# host file; the quiet/splash/plymouth boot is desktop-only and lives in
# desktop.nix (the headless server wants its console messages visible).
{
  boot.loader.efi.canTouchEfiVariables = true;
}
