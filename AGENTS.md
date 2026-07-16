# AGENTS.md

Vendor-neutral instructions for any LLM coding agent working in this repo.
This is the canonical agent guide — do **not** create a `CLAUDE.md` (or any
other provider-specific file) with real content; keep notes here. `CLAUDE.md`,
if present, is only a symlink to this file for tools that look for it (it's
gitignored and local-only).

## What this repo is

Anton's NixOS configuration, a Nix flake on `nixpkgs` unstable. Three hosts:

- **antonixos** — gaming desktop. Limine bootloader + secure boot, NVIDIA on
  the CachyOS kernel, Steam/gaming, 3440x1440@165 ultrawide (`DP-1`).
- **xps13** — laptop for schoolwork. systemd-boot, LUKS2 full disk encryption
  (root + swap, single passphrase), laptop power management (thermald,
  auto-cpufreq, powertop), bluetooth/upower, fwupd/LVFS firmware.
- **bank** — headless home server (migrated off TrueNAS SCALE; runbook in
  `docs/truenas-migration.md`). systemd-boot, ZFS data pool `vault` + sanoid
  snapshots, Docker compose stacks, NFS server, Tailscale subnet router for the
  home LAN, key-only SSH.

Desktop stack (antonixos + xps13 only): **niri** (Wayland compositor),
**noctalia** shell + greeter, **stylix** theming (catppuccin-mocha), kitty,
yazi, neovim (LazyVim), zsh. home-manager is wired in as a NixOS module for
user `anton` on every host; bank gets a lean headless profile.

## Layout

The guiding rule: a host file contains only what makes that machine unique;
everything shared is written once under `modules/nixos/`, and everything that
belongs to the user's session/dotfiles is written once under `home/`. Shared
config is split in two layers: `modules/nixos/base.nix` is the host-agnostic
foundation every machine imports (via the bundle or directly), and
`modules/nixos/default.nix` is base + the desktop/laptop GUI bundle. The
desktop hosts import `../../modules/nixos`; bank imports
`../../modules/nixos/base.nix` directly and layers its server config in its
host file.

```
flake.nix                     inputs + 3-line mkHost helper; each host = ./hosts/<name>
flake.lock
docs/
  truenas-migration.md        TrueNAS→NixOS runbook for bank (install + cutover)
hosts/
  antonixos/default.nix       desktop specifics (limine+SB, cachyos kernel, nvidia, steam)
  antonixos/wooting.nix       udev rule for Wooting keyboard (uaccess, drop power-switch tag)
  antonixos/hardware-configuration.nix
  xps13/default.nix           laptop specifics (systemd-boot, systemd initrd + resume for
                              the LUKS setup, bluetooth/upower, power mgmt, fwupd)
  xps13/hardware-configuration.nix  also holds the LUKS2 device entries (cryptroot/cryptswap)
  bank/default.nix            server specifics (ZFS `vault`, sanoid, docker, NFS server,
                              tailscale subnet router, sshd, localadm uid/gid 3000, lean HM)
  bank/hardware-configuration.nix
modules/nixos/                shared config, split by concern
  base.nix                    host-agnostic foundation: nix, locale, networking, boot,
                              users, caches + system.stateVersion. ALL hosts get this.
  default.nix                 the desktop/laptop bundle: base.nix + GUI modules below
                              + external flake modules (chaotic, stylix, niri, noctalia,
                              home-manager). antonixos/xps13 import this; bank does NOT.
  nix.nix                     nix daemon settings, GC, allowUnfree, insecure pkgs
  boot.nix                    EFI vars only (bootloader is per-host; quiet/splash boot
                              is desktop-only and lives in desktop.nix)
  locale.nix                  timezone/locale (Europe/Copenhagen, en_DK), console keymap
  networking.nix              NetworkManager, tailscale (bluetooth/upower are xps13-only)
  network-share.nix           bank's three NFS exports auto-mounted over tailscale under
                              /mnt/vault (desktop bundle only — bank is the server)
  audio.nix                   PipeWire (+rtkit)
  desktop.nix                 niri, greeter, quiet/plymouth boot, fonts, xdg portals,
                              noctalia greeter polkit, kdeconnect (+firewall ports)
  packages.nix                desktop-host packages + SUDO_ASKPASS (NOT on bank)
  users.nix                   user `anton` (wheel/video/networkmanager, zsh login shell)
  stylix.nix                  system stylix (catppuccin-mocha, dark)
  caches.nix                  ALL binary substituters/keys (single source of truth)
  home-manager.nix            wires HM into the desktop hosts, threads hostName+inputs
                              to home/ (bank has its own HM block in its host file)
home/
  default.nix                 desktop HM entrypoint: imports programs/*, xdg.userDirs
                              (lowercase), xdg.mimeApps URL-scheme handlers
  bank.nix                    lean HM profile for bank: zsh-headless, nvim, yazi only
  programs/
    niri/niri.nix             picks config-<host>.kdl by hostName
    niri/config-antonixos.kdl raw niri config (edited directly, NOT via niri-flake options)
    niri/config-xps13.kdl
    zsh.nix                   zsh + powerlevel10k + aliases (incl. `update`, `bupdate`)
    zsh-headless.nix          lean zsh for bank (starship prompt; no p10k/lsd/bat/fastfetch)
    nvim.nix                  neovim + lazyvim, defaultEditor
    kitty.nix                 kitty (JetBrainsMono Nerd Font)
    yazi.nix                  yazi file manager + clipboard plugin + keymap
    fastfetch.nix             declarative fastfetch config (hypr preset)
    noctalia.nix              noctalia shell settings (bar, dock, theme, wallpaper, session)
    bitwarden.nix             bitwarden desktop + SSH agent (IdentityAgent socket)
    stylix.nix                per-app stylix opt-outs (niri/kitty/noctalia)
    termfilechooser.nix       file-chooser portal wired to yazi-in-kitty
```

## Build & verify

- Rebuild (interactive): `sudo nixos-rebuild switch --flake ~/nixos-config#<host>`
  (zsh alias `update` targets `#$HOST`).
- **Deploy bank** from a desktop host (bank is headless): zsh alias `bupdate` =
  `nixos-rebuild switch --flake ~/nixos-config#bank --target-host anton@bank
  --use-remote-sudo` — builds locally, copies over Tailscale, activates with
  remote sudo (bank's wheel sudo is passwordless, SSH is key-only).
- **Agent-run rebuild:** use `sudo -A` so it prompts via the GUI askpass instead
  of blocking on a dead TTY: `sudo -A nixos-rebuild switch --flake ~/nixos-config#<host>`.
  `SUDO_ASKPASS` is set to ksshaskpass in `modules/nixos/packages.nix`.
- Eval-only check (no root, no build — use this to validate changes):
  `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
- Parse a single file: `nix-instantiate --parse <file>.nix`.
- Hosts are `antonixos`, `xps13` and `bank`. `$HOST` on each machine matches
  its hostname.

## Where things live (quick index)

- **A niri keybind / window-rule / startup app** → `home/programs/niri/config-<host>.kdl`
  (raw KDL, hand-written — this repo does *not* use niri-flake's nix settings API).
  The two KDL files are near-identical; keep them in sync when a change is generic.
- **A shell alias / prompt / env var for the login shell** → `home/programs/zsh.nix`
  (desktops) and/or `home/programs/zsh-headless.nix` (bank) — they are separate
  configs on purpose; add to both if the alias makes sense on a server.
- **A package for the desktop hosts** → `modules/nixos/packages.nix`
  (or `home.packages` in a `home/programs/*` module if it's user-scoped).
  This does NOT reach bank.
- **A package for one machine only** → that host's `default.nix` `environment.systemPackages`
  (bank's server CLI tools already live there).
- **A server concern** (ZFS/sanoid, NFS exports, Docker, subnet routing, sshd)
  → `hosts/bank/default.nix`.
- **Something every machine including bank needs** → one of the modules imported
  by `modules/nixos/base.nix` (nix/locale/networking/boot/users/caches).
- **A binary cache / substituter** → `modules/nixos/caches.nix` (not flake.nix nixConfig;
  see the note in that file re: first-build bootstrapping on a fresh machine).
- **Theming** → system-wide via stylix (`modules/nixos/stylix.nix`); apps that theme
  themselves opt out in `home/programs/stylix.nix` (currently niri, kitty,
  noctalia, yazi — anything noctalia's theme templates write must opt out, or
  HM activation fails on the clobbered file at the next-but-one rebuild).
  noctalia applies its own Catppuccin theme + templates to btop/kitty/niri/neovim/
  obsidian/yazi (see `home/programs/noctalia.nix` `theme.templates`).
- **The file picker** → termfilechooser → yazi in kitty (`home/programs/termfilechooser.nix`
  + portal config in `modules/nixos/desktop.nix`).
- **A URL-scheme / default-app handler** (e.g. `discord://` → equibop) →
  `xdg.mimeApps.defaultApplications` in `home/default.nix`.

## Host differences

antonixos is the gaming desktop, xps13 the schoolwork laptop, bank the headless
server — place "laptop-ish" things (battery, bluetooth, firmware) in xps13's
host file, not in a shared module.

| Concern     | antonixos                         | xps13                              | bank                             |
|-------------|-----------------------------------|------------------------------------|----------------------------------|
| Role        | gaming desktop                    | schoolwork laptop                  | headless home server             |
| Bootloader  | Limine + secure boot + Windows    | systemd-boot                       | systemd-boot                     |
| Kernel      | `linuxPackages_cachyos`           | `linuxPackages_latest`             | nixpkgs default (ZFS-compatible) |
| GPU / GUI   | NVIDIA (cachyos pkg, open module) | Intel (default)                    | none (no desktop bundle)         |
| xkb layout  | `eu`                              | `dk`                               | n/a                              |
| Disk encryption | none                          | LUKS2 (root + swap, one passphrase) | none                            |
| Power/peripherals | bluetooth                   | thermald, auto-cpufreq, powertop, bluetooth, upower | none            |
| Firmware    | none                              | fwupd/LVFS                         | none                             |
| Extras      | Steam, gamescope, protontricks, sbctl | none                           | ZFS+sanoid, Docker, NFS server, subnet router, sshd |

fwupd is laptop-only — never add it to antonixos. bank must NOT use the CachyOS
kernel: ZFS needs a kernel with a matching module, so its kernel stays unset
(nixpkgs default).

## Conventions

- For any nixpkgs package / NixOS / home-manager option question, use the
  `nixos` MCP server rather than guessing — training data lags nixpkgs. It's
  wired in `.mcp.json`; `mcp-nixos` is installed system-wide.
- Home directories are lowercase (`downloads`, `videos`, …) via `xdg.userDirs`
  in `home/default.nix`.
- `system.stateVersion` (in `modules/nixos/base.nix`) and `home.stateVersion`
  are `26.05`. Don't bump casually.
- nixpkgs is unstable; `allowUnfree = true`. Insecure-package allowances go in
  `modules/nixos/nix.nix` `permittedInsecurePackages`.
- Don't commit `.bak` / `.backup` files (home-manager writes `*.backup` on
  clobber; they're byproducts, not config — both patterns are gitignored).
- Only commit or push when explicitly asked.

## Gotchas already discovered (don't re-derive these)

- **noctalia greeter sync** runs `pkexec noctalia-greeter-apply-appearance`.
  It's authorized without a prompt via a polkit rule in `modules/nixos/desktop.nix`
  (the KDE polkit agent segfaults under stylix's Kvantum style, and the helper's
  own policy action never binds). `security.polkit.enablePkexecWrapper = true` is
  required because nixpkgs made the setuid pkexec wrapper opt-in.
- **fastfetch icons** in `home/programs/fastfetch.nix` are written as `\uXXXX`
  escapes, not raw Nerd Font glyphs — the glyphs live in the Private Use Area and
  get silently stripped on edit. The logo uses `type: "kitty-direct"` (plain
  `kitty` needs image libs nixpkgs' fastfetch lacks) and an absolute path (no `~`).
- **SSH agent** is Bitwarden (`home/programs/bitwarden.nix` sets `SSH_AUTH_SOCK`
  and `IdentityAgent` to the bitwarden socket).
- **NFS shares** on the desktop hosts mount bank's exports at
  `/mnt/vault/{data,configs,localadm}` (`modules/nixos/network-share.nix`).
  They are `noauto`/automount over Tailscale — they only mount on access,
  address the server by its MagicDNS name `bank`, and require `tailscaled` up.
  The server side (exports, all_squash to uid/gid 3000) is in `hosts/bank/default.nix`.
- **home-manager wiring is split**: `modules/nixos/home-manager.nix` (desktop
  bundle) points at `home/default.nix`; bank carries its own `home-manager`
  block pointing at the slim `home/bank.nix`. HM settings changed in one place
  won't reach the other.
- **xps13 is LUKS2-encrypted** (retrofitted in place with `cryptsetup reencrypt`,
  no reinstall). Both volumes share one passphrase: `boot.initrd.systemd.enable`
  (in `hosts/xps13/default.nix`) makes stage-1 retry it on the swap volume, so
  boot shows a single prompt — don't remove that option or the second prompt
  comes back. The initrd prompt uses the `dk-latin1` console keymap from
  `locale.nix`. The UUIDs in `boot.initrd.luks.devices` are the LUKS *container*
  UUIDs; the btrfs filesystem UUID predates the encryption and is unchanged.
  Swap runs through `/dev/mapper/cryptswap` and is also the hibernation resume
  device (`boot.resumeDevice`). Argon2id makes each unlock take a few seconds —
  that's by design, not a hang. The other hosts are unencrypted.
- **URL-scheme handlers** live in `xdg.mimeApps.defaultApplications` in
  `home/default.nix`. Enabling `xdg.mimeApps` makes `~/.config/mimeapps.list` a
  read-only store symlink, so apps can no longer self-register schemes at runtime
  (Electron's `setAsDefaultProtocolClient` silently no-ops). Any handler an app
  used to register imperatively (`claude-cli`, deadlock mod manager, …) must be
  listed there too, or it regresses. Equibop's `discord://` handler is set this
  way because its self-registration never stuck on NixOS.
