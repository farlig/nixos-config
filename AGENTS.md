# AGENTS.md

Vendor-neutral instructions for any LLM coding agent working in this repo.
This is the canonical agent guide — do **not** create a `CLAUDE.md` (or any
other provider-specific file) with real content; keep notes here. `CLAUDE.md`,
if present, is only a symlink to this file for tools that look for it.

## What this repo is

Anton's NixOS configuration, a Nix flake on `nixpkgs` unstable. Two hosts:

- **antonixos** — desktop. Limine bootloader + secure boot, NVIDIA on the
  CachyOS kernel, Steam/gaming.
- **xps13** — laptop. systemd-boot, laptop power management (thermald,
  auto-cpufreq, powertop).

Desktop stack: **niri** (Wayland compositor), **noctalia** shell + greeter,
**stylix** theming (catppuccin-mocha), kitty, yazi, neovim (LazyVim), zsh.
home-manager is wired in as a NixOS module for user `anton`.

## Layout

The guiding rule: a host file contains only what makes that machine unique;
everything shared is written once under `modules/nixos/`.

- `flake.nix` — inputs + a 3-line `mkHost` helper; each host is just
  `./hosts/${hostName}`.
- `hosts/<name>/default.nix` — ONLY that machine's specifics (bootloader,
  kernel, nvidia/power mgmt, xkb layout, hostname) + `hardware-configuration.nix`.
- `modules/nixos/` — everything shared by all hosts, split by concern
  (`default.nix` aggregates and pulls in the external flake modules;
  `nix.nix`, `locale.nix`, `networking.nix`, `boot.nix`, `audio.nix`,
  `desktop.nix`, `packages.nix`, `users.nix`, `network-share.nix`, `stylix.nix`,
  `caches.nix`, `home-manager.nix`).
- `home/` — home-manager config (`default.nix` + `programs/`, including
  `programs/termfilechooser.nix`).

## Build & verify

- Rebuild: `sudo nixos-rebuild switch --flake ~/nixos-config#<host>`
  (zsh alias `update` targets `#$HOST`).
- Eval-only check (no root, no build):
  `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
- Parse a single file: `nix-instantiate --parse <file>.nix`.

## Conventions

- For any nixpkgs package / NixOS / home-manager option question, use the
  `nixos` MCP server rather than guessing — training data lags nixpkgs.
- Home directories are lowercase (`downloads`, `videos`, …) via `xdg.userDirs`.
- Don't commit `.bak` files.
- Only commit or push when explicitly asked.
