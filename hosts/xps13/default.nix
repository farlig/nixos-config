{ pkgs, ... }:

# xps13 — the laptop. Everything here is specific to this machine;
# shared configuration lives in ../../modules/nixos.
{
  imports = [
    ../../modules/nixos
    ./hardware-configuration.nix
  ];

  networking.hostName = "xps13";

  # Bootloader: systemd-boot, no menu delay.
  boot.loader.systemd-boot.enable = true;
  # Cap boot-menu generations so the ESP can't fill up.
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.timeout = 0;

  # Full disk encryption (LUKS2, see hardware-configuration.nix): systemd
  # stage-1 reuses the passphrase across volumes, so root + swap unlock with
  # a single prompt, rendered through plymouth.
  boot.initrd.systemd.enable = true;
  # Resume from the encrypted swap volume (hibernation support; lid-close
  # stays poweroff — hibernation is possible, not the default).
  boot.resumeDevice = "/dev/mapper/cryptswap";

  # Firmware updates via LVFS (Dell has good LVFS coverage).
  services.fwupd.enable = true;

  # Flatpak — for the Bitwarden desktop app on this host. The nixpkgs Bitwarden
  # build's biometric unlock panics on a null clientKeyPartB64 (upstream
  # bitwarden/clients#15790); the Flatpak build works. The app, its flathub
  # remote and the SSH-agent socket override are declared via nix-flatpak in
  # home/programs/bitwarden-flatpak.nix (imported for xps13 in home/default.nix).
  services.flatpak.enable = true;

  # Bitwarden biometric unlock — both the desktop app and the Firefox extension —
  # authenticates through this polkit action. The Flatpak can't register a system
  # polkit policy itself (Bitwarden's docs have Flatpak users drop it into
  # /usr/share/polkit-1/actions by hand), and we no longer install the nixpkgs
  # bitwarden-desktop package that used to ship it. Register it declaratively, or
  # unlock fails with "Action com.bitwarden.Bitwarden.unlock is not registered".
  # Verbatim copy of apps/desktop/resources/com.bitwarden.desktop.policy upstream.
  environment.systemPackages = [
    (pkgs.writeTextDir "share/polkit-1/actions/com.bitwarden.Bitwarden.policy" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE policyconfig PUBLIC
       "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
       "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
      <policyconfig>
          <action id="com.bitwarden.Bitwarden.unlock">
            <description>Unlock Bitwarden</description>
            <message>Authenticate to unlock Bitwarden</message>
            <defaults>
              <allow_any>no</allow_any>
              <allow_inactive>no</allow_inactive>
              <allow_active>auth_self</allow_active>
            </defaults>
          </action>
      </policyconfig>
    '')
  ];

  # Latest mainline kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Disable secretmem (memfd_secret) system-wide. Bitwarden Desktop (>= 2026.5.0,
  # via Electron/Chromium) parks its decrypted vault in memfd_secret memory,
  # whose pages are unmapped from the kernel direct map and so cannot be written
  # into a hibernation image — the kernel responds by disabling hibernation
  # entirely (`/sys/power/disk` reads [disabled]) for as long as any secretmem
  # user exists. That silently degraded HandleLidSwitch=suspend-then-hibernate to
  # a plain, battery-draining s2idle suspend (there is no S3 on this firmware),
  # so a bagged laptop ran flat instead of hibernating. Turning secretmem off
  # makes memfd_secret fall back to ordinary memory and restores hibernation.
  # Upstream bug: https://github.com/bitwarden/clients/issues/21661
  # Trade-off: those secrets now live in normal, swappable RAM; but a hibernation
  # image writes all of RAM to swap anyway, and cryptswap is LUKS-encrypted, so
  # they are protected at rest regardless. Verify with `cat /sys/power/disk`.
  boot.kernelParams = [ "secretmem.enable=0" ];

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

  # Laptop peripherals/battery. upower is wanted only here — the desktop and
  # server go without (bluetooth is also on antonixos these days).
  hardware.bluetooth.enable = true;
  services.upower.enable = true;

  # Fingerprint reader (Goodix 27c6:63bc). Supported by libfprint's open
  # goodixmoc driver, so no proprietary TOD blob is needed. Enabling fprintd
  # makes security.pam.services.<name>.fprintAuth default to true across the
  # whole PAM stack, giving fingerprint auth for sudo, polkit and the noctalia
  # lock screen. Enroll a finger once with `fprintd-enroll` (test: `fprintd-verify`).
  services.fprintd.enable = true;

  # ...but NOT at the greetd login screen. pam_fprintd is `sufficient` and runs
  # before pam_gnome_keyring, so authenticating with a fingerprint short-circuits
  # the stack and the login keyring never gets its password — it stays locked and
  # prompts later. A fingerprint fundamentally cannot unlock the keyring (it's
  # encrypted with the password), so login stays password-only to keep the keyring
  # auto-unlocking. Fingerprint is still used everywhere else, incl. the lock screen.
  security.pam.services.greetd.fprintAuth = false;

  # Laptop power management. Lid close suspends, then hibernates after 15 min
  # — the LUKS keys leave RAM at that point, so a bagged laptop ends up as
  # protected as if powered off, without losing the session on every lid close.
  # On AC the lid only locks (swayidle catches the logind lock signal; see
  # home/programs/idle.nix for the idle chain).
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "lock";
  };
  systemd.sleep.settings.Sleep.HibernateDelaySec = "15min";
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
