{ ... }:

# Connectivity common to all hosts. The hostname itself is set per-host in
# hosts/<name>/default.nix. Bluetooth is per-host (both desktops enable it, the
# headless server does not) and upower is xps13-only.
{
  networking.networkmanager.enable = true;

  services.tailscale.enable = true;
}
