{ ... }:

# Connectivity common to all hosts. The hostname itself is set per-host in
# hosts/<name>/default.nix. Bluetooth and upower are laptop concerns and live
# in hosts/xps13 — the gaming desktop and the headless server want neither.
{
  networking.networkmanager.enable = true;

  services.tailscale.enable = true;
}
