{ ... }:

{
  services.rpcbind.enable = true;
  boot.supportedFilesystems = [ "nfs" ];

  fileSystems."/mnt/truenas" = {
    device = "100.88.141.82:/mnt/Pool1/data";
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
