{ pkgs, ... }:

# xps13 — the laptop. Everything here is specific to this machine;
# shared configuration lives in ../../modules/nixos.
{
  imports = [
    ../../modules/nixos
    ./hardware-configuration.nix
  ];

  # NOTE: the original hosts/xps13/configuration.nix set this to "antonixos",
  # which looks like a copy-paste bug (both machines ended up named antonixos).
  # Corrected here — see proposal/README.md. Change back if it was intentional.
  networking.hostName = "xps13";

  # Bootloader: systemd-boot, no menu delay.
  boot.loader.systemd-boot.enable = true;
  # Cap boot-menu generations so the ESP can't fill up.
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.timeout = 0;

  # Firmware updates via LVFS (Dell has good LVFS coverage).
  services.fwupd.enable = true;

  # Latest mainline kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Wireless is managed by NetworkManager (enabled in modules/nixos/networking.nix).
  # NM's default wpa_supplicant backend already turns on networking.wireless.enable
  # itself (integrated D-Bus mode), so no explicit wpa_supplicant config is needed
  # here. Only set networking.wireless.* if switching to a standalone, hand-declared
  # wpa_supplicant setup instead of NM (see NixOS wiki: Wpa_supplicant).

  # Keyboard layout for this machine (console keymap is shared in locale.nix).
  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  # Laptop power management.
  services.logind.settings.Login = {
    HandleLidSwitch = "poweroff";
    HandleLidSwitchExternalPower = "lock";
  };
  services.thermald.enable = true;
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };
  powerManagement.powertop.enable = true;
}
