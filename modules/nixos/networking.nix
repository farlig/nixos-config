{ ... }:

# Connectivity and power/session daemons common to all hosts. The hostname
# itself is set per-host in hosts/<name>/default.nix.
{
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;

  services.upower.enable = true;

  services.tailscale.enable = true;
}
