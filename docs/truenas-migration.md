# TrueNAS SCALE → NixOS migration (host `bank`, pool `vault`)

Runbook for migrating the home server off TrueNAS SCALE onto NixOS as a third
host in this flake. The **repo work is already done and committed** (see the
`bank` host + the base/desktop module split); what remains is the on-the-box
install and cutover described below.

## What changed in the repo

- `hosts/bank/` — new headless host: ZFS pool `vault` import, autoscrub + trim,
  sanoid snapshots, Docker, NFS server, key-only SSH, passwordless sudo for
  wheel, `localadm` (uid/gid 3000). `hardware-configuration.nix` there is a
  **placeholder** to regenerate on the box.
- `modules/nixos/base.nix` — host-agnostic foundation (nix, locale, networking,
  boot, users, caches, stateVersion). `bank` imports this directly.
- `modules/nixos/default.nix` — now the desktop/laptop bundle (base + GUI stack).
  antonixos/xps13 unchanged.
- `modules/nixos/network-share.nix` — now mounts `bank:/mnt/vault/data`.

## Box inventory (source of the config)

- **TrueNAS SCALE 25.04.2.6**, OpenZFS.
- **Install target:** `nvme0n1` (931 GB KINGSTON SNV3S1000G, serial
  50026B738399AB73) — held the TrueNAS `boot-pool`. Gets repartitioned. The six
  HDDs (`sda`–`sdf`) hold the data pool and are **never touched**.
- **Data pool `Pool1` → renamed `vault`:** ~54 TB, 21 TB used, `lz4`, 2× raidz1
  striped (sda/sdd/sde + sdb/sdc/sdf), **encryption OFF**, last scrub clean.
- **Keep:** `data` (~21 TB media), `configs/*` (~25 app config dirs), `home`.
- **Drop:** `ix-apps/*` (TrueNAS docker root/catalog), `.system/*`, `.ix-virt/*`,
  VMs (`h3sql` zvol, Windows ISO — retired, no libvirt on NixOS).
- **Compose:** ~25 stacks managed in **Portainer** — export before wiping.
- **NFS:** 3 exports (`data`, `configs`, `home/localadm`), all_squash to uid/gid
  3000. **No replication** exists (snapshots are the only copies).
- **Snapshots:** twice-daily, 2-week retention on `configs` (recursive) + `data`.

## Before shutting the box down for good

1. **Export every Portainer stack** (compose + env) and note each app's
   `PUID`/`PGID` + bind paths. Portainer runs under TrueNAS's own Docker, so once
   the NVMe is wiped you can't get these back — save them off the boot disk.
2. Confirm backups of anything irreplaceable (no replication exists).
3. Stop the apps so nothing is mid-write to `configs`.
4. **Optional clean export:** TrueNAS → Storage → the pool → Export/Disconnect,
   with the *Destroy data* / *Delete config* boxes **UNCHECKED**. This clears the
   "active on another system" flag so the NixOS import needs no `-f`. Skipping it
   is fine — use `-f` on import instead.
5. **Do not `zpool upgrade`** — leaving feature flags as-is keeps the "reinstall
   TrueNAS + re-import" rollback open.

## Install (NixOS minimal ISO)

Boot the NixOS minimal ISO, then as root:

```bash
sudo -i
# CONFIRM: nvme0n1 = the 931G KINGSTON. The six sd* are the vault HDDs — leave them.
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE

# Partition the NVMe only (wipes TrueNAS's OS disk): 1G ESP + rest ext4
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1025MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root ext4 1025MiB 100%
mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos   /dev/nvme0n1p2

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/BOOT /mnt/boot

# Generate the real hardware config
nixos-generate-config --root /mnt

# Get the flake (git may need: nix-shell -p git)
git clone https://github.com/farlig/nixos-config /mnt/root/nixos-config
cp /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/root/nixos-config/hosts/bank/hardware-configuration.nix
cd /mnt/root/nixos-config
git add hosts/bank/hardware-configuration.nix   # so the flake sees the real file

nixos-install --flake .#bank    # sets a root password at the end — set one
reboot
```

The flake clones to `/root/nixos-config` on the installed system, so it persists.
(If the repo is private, the HTTPS clone needs a GitHub token, or use the SSH
remote with a key on the installer.)

## First boot into `bank` — import + rename the pool

```bash
zpool import                                     # should list Pool1
zpool import -d /dev/disk/by-id -f Pool1 vault   # drop -f if you cleanly exported
zfs set mountpoint=/mnt/vault vault
zfs inherit -r mountpoint vault
zfs list -o name,mountpoint                      # confirm data/configs/home under /mnt/vault
```

`boot.zfs.extraPools = [ "vault" ]` auto-imports it on later boots. Then:

```bash
sudo tailscale up
# bring up each exported Portainer stack, rewriting bind paths /mnt/Pool1 → /mnt/vault
# (keep each app's PUID/PGID so ownership on the pool still matches)
```

## Repoint desktop/laptop

On antonixos/xps13: `git pull` then `sudo -A nixos-rebuild switch`. The NFS mount
`/mnt/truenas` now serves from `bank:/mnt/vault/data`.

## Verification

```bash
zpool status vault                 # ONLINE, 0 errors
zfs list -o name,mountpoint        # under /mnt/vault
systemctl status nfs-server
showmount -e
systemctl status sanoid.timer
docker compose ps                  # per stack
ssh anton@bank                     # works by key, fails by password
```

## Decisions baked into the config (don't re-derive)

- **Headless**, reuse `anton`, **key-only SSH** (`PasswordAuthentication=false`,
  `PermitRootLogin="no"`), **passwordless sudo for wheel** (no local password on
  a key-only box).
- Root = plain **ext4 on the NVMe**; ZFS only for the imported `vault` data.
- `networking.hostId = "9d67a92d"` (required by ZFS; keep stable).
- Stock kernel (ZFS-compatible), **not** the CachyOS kernel used on antonixos.
- Docker data-root stays on `/var/lib/docker` (fast NVMe), not the pool.
- `localadm` at uid/gid 3000 matches the NFS `all_squash` target + file ownership.
- **Never `zpool upgrade vault`** until the TrueNAS rollback is no longer wanted.

## Later: declarative containers

Once the stacks run on compose, convert them one at a time to
`virtualisation.oci-containers.containers.<name>` (`backend = "docker"`);
`compose2nix` bootstraps from the exported compose files. Keep `environmentFiles`,
volumes, `dependsOn`, `PUID`/`PGID`.
