{ pkgs, inputs, hostName, ... }:

# bank — the home server, migrated from a TrueNAS SCALE box. Headless: it imports
# the host-agnostic base (NOT ../../modules/nixos, which is the desktop bundle)
# and layers ZFS, Docker, NFS and snapshots on top. See docs/truenas-migration.md
# for the full migration runbook; the data pool `vault` was renamed from the
# TrueNAS `Pool1` on import.
{
  imports = [
    ../../modules/nixos/base.nix
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "bank";
  # Required by ZFS to detect pool ownership; unique per machine, keep stable.
  networking.hostId = "9d67a92d";

  # Bootloader: systemd-boot on the NVMe (the disk that held the TrueNAS boot
  # pool). Root is plain ext4 there; ZFS is used only for the data pool below.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Stock kernel — ZFS needs a kernel it has a matching module for, so NOT the
  # CachyOS kernel used on antonixos. The nixpkgs default tracks a ZFS-supported
  # series; leave it unset unless a rebuild complains, then pin an LTS here.

  ### ZFS — the data pool `vault` (renamed from TrueNAS `Pool1`) ##############
  boot.supportedFilesystems = [ "zfs" ];
  # Import the data pool at boot; its datasets keep their own mountpoints under
  # /mnt/vault. First manual import on the box:
  #   zpool import -d /dev/disk/by-id Pool1 vault
  #   zfs set mountpoint=/mnt/vault vault && zfs inherit -r mountpoint vault
  boot.zfs.extraPools = [ "vault" ];
  # Don't force-import a pool that wasn't cleanly exported (guards against
  # importing disks still claimed by another system). This is the 26.11 default.
  boot.zfs.forceImportRoot = false;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  ### Snapshots — replaces the TrueNAS periodic snapshot tasks ################
  # Old policy: twice-daily, 2-week retention on configs (recursive) + data.
  # sanoid takes at most one snapshot per period; `daily = 14` keeps ~2 weeks.
  # No replication target existed on the old box — snapshots are the only copies
  # and live on the same pool. Worth adding syncoid to an offsite pool later.
  services.sanoid = {
    enable = true;
    datasets = {
      "vault/configs" = {
        recursive = true;
        autosnap = true;
        autoprune = true;
        daily = 14;
      };
      "vault/data" = {
        autosnap = true;
        autoprune = true;
        daily = 14;
      };
    };
  };

  ### Docker — runs the compose stacks (exported from Portainer) ##############
  # Data-root defaults to /var/lib/docker on the fast NVMe root — deliberately
  # NOT on the spinning `vault` pool. App config/data still lives under
  # /mnt/vault/configs and /mnt/vault/data via each stack's bind mounts.
  virtualisation.docker.enable = true;
  # Let anton drive docker without sudo (merges with the groups in users.nix).
  users.users.anton.extraGroups = [ "docker" ];

  ### Tailscale subnet router — advertise the home LAN to the tailnet ########
  # Lets remote tailnet nodes reach the 192.168.1.0/24 home network *through*
  # bank. `useRoutingFeatures = "server"` just enables IP forwarding (additive);
  # extraSetFlags runs `tailscale set` in place (no reconnect), so deploying this
  # won't drop an existing SSH session. The route must still be approved once in
  # the admin console (Machines → bank → Edit route settings) before it carries
  # traffic. Nodes physically on 192.168.1.0/24 should NOT --accept-routes, or
  # they'd send their own LAN traffic back through the tunnel.
  services.tailscale.useRoutingFeatures = "server";
  services.tailscale.extraSetFlags = [ "--advertise-routes=192.168.1.0/24" ];

  ### NFS server — the three exports carried over from TrueNAS ################
  # all_squash maps every client to uid/gid 3000 (localadm), matching on-disk
  # ownership. Clients are the Tailscale CGNAT range.
  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/vault/data          100.64.0.0/10(rw,sec=sys,all_squash,anonuid=3000,anongid=3000,no_subtree_check)
      /mnt/vault/configs       100.64.0.0/10(rw,sec=sys,all_squash,anonuid=3000,anongid=3000,no_subtree_check)
      /mnt/vault/home/localadm 100.64.0.0/10(rw,sec=sys,all_squash,anonuid=3000,anongid=3000,subtree_check)
    '';
  };

  ### localadm — the identity the pool's files are owned by (uid/gid 3000) ####
  users.groups.localadm.gid = 3000;
  users.users.localadm = {
    uid = 3000;
    group = "localadm";
    isSystemUser = true;
    description = "TrueNAS file-ownership identity (NFS all_squash target)";
  };

  ### SSH — key-only, hardened ################################################
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  # anton's SSH public key (from Bitwarden). Password auth is off, so this is the
  # only remote access; console login on the physical machine is the fallback.
  users.users.anton.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZruSAPUJsVNFibcfUFw5yfqOqkSFut19mPMsHLVcjJ"
  ];

  # Headless box reached only by SSH key: anton has no local password, so let
  # wheel sudo without one (a password prompt would be unanswerable over a
  # key-only login).
  security.sudo.wheelNeedsPassword = false;

  # Lean home-manager profile: zsh (headless variant), nvim and yazi only — no
  # GUI/theming. The desktop hosts wire this via modules/nixos/home-manager.nix
  # pointed at home/default.nix; bank points at the slim home/bank.nix instead.
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit (inputs) lazyvim; inherit hostName inputs; };
    users.anton.imports = [ ../../home/bank.nix ];
  };

  # Headless server tooling (the GUI packages.nix is desktop-only).
  environment.systemPackages = with pkgs; [
    docker-compose
    git
    btop
    smartmontools
    rsync
    tmux
    pciutils
    # sqlite3 CLI with readline (the plain `sqlite` package's binary has no line
    # editing/history) — for poking at app databases like Jellyfin's.
    sqlite-interactive
    # Terminfo for kitty, so SSHing in from a kitty terminal (TERM=xterm-kitty)
    # doesn't break pagers/line-editing. This box has no GUI/kitty itself; it's
    # just the terminfo entry the remote side needs.
    kitty.terminfo
  ];
}
