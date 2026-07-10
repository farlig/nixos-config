{ ... }:

# NFS data share from the `bank` home server, auto-mounted over Tailscale.
# (Was the TrueNAS box; bank replaced it — the pool `Pool1` was renamed `vault`,
# so the export path is now /mnt/vault/data, mounted locally at /mnt/vault. Uses
# the MagicDNS name `bank` rather than a hard-coded Tailscale IP.)
{
  services.rpcbind.enable = true;
  boot.supportedFilesystems = [ "nfs" ];

  fileSystems."/mnt/vault" = {
    device = "bank:/mnt/vault/data";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10"
      "x-systemd.requires=tailscaled.service"
      "x-systemd.after=tailscaled.service"
      "_netdev"
      "soft"
      "timeo=30"
    ];
  };
}
