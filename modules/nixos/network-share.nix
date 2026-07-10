{ ... }:

# NFS shares from the `bank` home server, auto-mounted over Tailscale.
# (Was the TrueNAS box; bank replaced it — the pool `Pool1` was renamed `vault`.)
# Uses the MagicDNS name `bank` rather than a hard-coded Tailscale IP. Each of
# bank's three exports is mounted under /mnt/vault on the client, generated from
# the `shares` table below (client mountpoint -> server export path).
let
  shares = {
    "/mnt/vault/data" = "/mnt/vault/data";
    "/mnt/vault/configs" = "/mnt/vault/configs";
    "/mnt/vault/localadm" = "/mnt/vault/home/localadm";
  };

  mountOptions = [
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
in
{
  services.rpcbind.enable = true;
  boot.supportedFilesystems = [ "nfs" ];

  fileSystems = builtins.mapAttrs (_mountpoint: exportPath: {
    device = "bank:${exportPath}";
    fsType = "nfs";
    options = mountOptions;
  }) shares;
}
