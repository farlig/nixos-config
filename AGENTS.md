# AGENTS.md

Vendor-neutral instructions for any LLM coding agent working in this repo.
This is the canonical agent guide — do **not** create a `CLAUDE.md` (or any
other provider-specific file) with real content; keep notes here. `CLAUDE.md`,
if present, is only a symlink to this file for tools that look for it (it's
gitignored and local-only).

## What this repo is

Anton's NixOS configuration, a Nix flake on `nixpkgs` unstable. Two hosts:

- **antonixos** — desktop. Limine bootloader + secure boot, NVIDIA on the
  CachyOS kernel, Steam/gaming, 3440x1440@165 ultrawide (`DP-1`).
- **xps13** — laptop. systemd-boot, laptop power management (thermald,
  auto-cpufreq, powertop), fwupd/LVFS firmware, opensnitch.

Desktop stack: **niri** (Wayland compositor), **noctalia** shell + greeter,
**stylix** theming (catppuccin-mocha), kitty, yazi, neovim (LazyVim), zsh.
home-manager is wired in as a NixOS module for user `anton`.

## Layout

The guiding rule: a host file contains only what makes that machine unique;
everything shared is written once under `modules/nixos/`, and everything that
belongs to the user's session/dotfiles is written once under `home/`.

```
flake.nix                     inputs + 3-line mkHost helper; each host = ./hosts/<name>
flake.lock
hosts/
  antonixos/default.nix       desktop specifics (limine+SB, cachyos kernel, nvidia, steam)
  antonixos/wooting.nix       udev rule for Wooting keyboard (uaccess, drop power-switch tag)
  antonixos/hardware-configuration.nix
  xps13/default.nix           laptop specifics (systemd-boot, power mgmt, fwupd)
  xps13/hardware-configuration.nix
modules/nixos/                everything shared by ALL hosts, split by concern
  default.nix                 aggregates local modules + wires external flake modules
  nix.nix                     nix daemon settings, GC, allowUnfree, insecure pkgs
  boot.nix                    shared quiet/splash boot + EFI vars (bootloader is per-host)
  locale.nix                  timezone/locale (Europe/Copenhagen, en_DK), console keymap
  networking.nix              NetworkManager, bluetooth, upower, tailscale
  network-share.nix           TrueNAS NFS auto-mount over tailscale at /mnt/truenas
  audio.nix                   PipeWire (+rtkit)
  desktop.nix                 niri, greeter, fonts, xdg portals, noctalia greeter polkit
  packages.nix                system-wide packages + SUDO_ASKPASS
  users.nix                   user `anton` (wheel/video/networkmanager, zsh)
  stylix.nix                  system stylix (catppuccin-mocha, dark)
  caches.nix                  ALL binary substituters/keys (single source of truth)
  home-manager.nix            wires HM into system, threads hostName+inputs to home/
home/
  default.nix                 HM entrypoint: imports programs/*, xdg.userDirs (lowercase)
  programs/
    niri/niri.nix             picks config-<host>.kdl by hostName
    niri/config-antonixos.kdl raw niri config (edited directly, NOT via niri-flake options)
    niri/config-xps13.kdl
    zsh.nix                   zsh + powerlevel10k + aliases (incl. `update`)
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
- **Agent-run rebuild:** use `sudo -A` so it prompts via the GUI askpass instead
  of blocking on a dead TTY: `sudo -A nixos-rebuild switch --flake ~/nixos-config#<host>`.
  `SUDO_ASKPASS` is set to ksshaskpass in `modules/nixos/packages.nix`.
- Eval-only check (no root, no build — use this to validate changes):
  `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
- Parse a single file: `nix-instantiate --parse <file>.nix`.
- Hosts are `antonixos` and `xps13`. `$HOST` on each machine matches its hostname.

## Where things live (quick index)

- **A niri keybind / window-rule / startup app** → `home/programs/niri/config-<host>.kdl`
  (raw KDL, hand-written — this repo does *not* use niri-flake's nix settings API).
  The two KDL files are near-identical; keep them in sync when a change is generic.
- **A shell alias / prompt / env var for the login shell** → `home/programs/zsh.nix`.
- **A package for every machine** → `modules/nixos/packages.nix`
  (or `home.packages` in a `home/programs/*` module if it's user-scoped).
- **A package for one machine only** → that host's `default.nix` `environment.systemPackages`.
- **A binary cache / substituter** → `modules/nixos/caches.nix` (not flake.nix nixConfig;
  see the note in that file re: first-build bootstrapping on a fresh machine).
- **Theming** → system-wide via stylix (`modules/nixos/stylix.nix`); apps that theme
  themselves opt out in `home/programs/stylix.nix` (currently niri, kitty, noctalia).
  noctalia applies its own Catppuccin theme + templates to btop/kitty/niri/neovim/
  obsidian/yazi (see `home/programs/noctalia.nix` `theme.templates`).
- **The file picker** → termfilechooser → yazi in kitty (`home/programs/termfilechooser.nix`
  + portal config in `modules/nixos/desktop.nix`).
- **A URL-scheme / default-app handler** (e.g. `discord://` → equibop) →
  `xdg.mimeApps.defaultApplications` in `home/default.nix`.

## Host differences (antonixos vs xps13)

| Concern     | antonixos                         | xps13                              |
|-------------|-----------------------------------|------------------------------------|
| Bootloader  | Limine + secure boot + Windows    | systemd-boot                       |
| Kernel      | `linuxPackages_cachyos`           | `linuxPackages_latest`             |
| GPU         | NVIDIA (cachyos pkg, open module) | Intel (default)                    |
| xkb layout  | `eu`                              | `dk`                               |
| Power       | none                              | thermald, auto-cpufreq, powertop   |
| Firmware    | none                              | fwupd/LVFS                         |
| Extras      | Steam, gamescope, protontricks, sbctl | opensnitch                     |

fwupd is laptop-only — never add it to antonixos.

## Conventions

- For any nixpkgs package / NixOS / home-manager option question, use the
  `nixos` MCP server rather than guessing — training data lags nixpkgs. It's
  wired in `.mcp.json`; `mcp-nixos` is installed system-wide.
- Home directories are lowercase (`downloads`, `videos`, …) via `xdg.userDirs`
  in `home/default.nix`.
- `system.stateVersion` / `home.stateVersion` are `26.05`. Don't bump casually.
- nixpkgs is unstable; `allowUnfree = true`. Insecure-package allowances go in
  `modules/nixos/nix.nix` `permittedInsecurePackages`.
- Don't commit `.bak` / `.backup` files (home-manager writes `*.backup` on
  clobber; they're byproducts, not config).
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
- **NFS share** at `/mnt/truenas` is `noauto`/automount over Tailscale — it only
  mounts on access and requires `tailscaled` up.
- **URL-scheme handlers** live in `xdg.mimeApps.defaultApplications` in
  `home/default.nix`. Enabling `xdg.mimeApps` makes `~/.config/mimeapps.list` a
  read-only store symlink, so apps can no longer self-register schemes at runtime
  (Electron's `setAsDefaultProtocolClient` silently no-ops). Any handler an app
  used to register imperatively (`claude-cli`, deadlock mod manager, …) must be
  listed there too, or it regresses. Equibop's `discord://` handler is set this
  way because its self-registration never stuck on NixOS.
