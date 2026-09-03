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
- **bank** — headless home server. systemd-boot, ZFS data pool `vault` + sanoid
  snapshots, Docker compose stacks, NFS server, Tailscale subnet router for the
  home LAN, key-only SSH. `docs/truenas-migration.md` is the runbook for standing
  the box up from scratch.

Desktop stack (antonixos + xps13 only): **niri** (Wayland compositor),
**noctalia** shell + greeter, **stylix** theming (catppuccin-mocha), kitty,
yazi, neovim (LazyVim), zsh. home-manager is wired in as a NixOS module for
user `anton` on every host; bank gets a lean headless profile.

antonixos and bank are the machines this config is deployed to. xps13's host
files stay in the repo and must keep evaluating, but the laptop is not currently
running NixOS.

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
  truenas-migration.md        install runbook for bank (partitioning, pool import, cutover)
hosts/
  antonixos/default.nix       desktop specifics (limine+SB, cachyos kernel, nvidia, steam,
                              nix-ld for foreign binaries, flatpak for the Flathub apps)
  antonixos/udev.nix          peripheral access: QMK/VIA udev rules + a Wooting rule
                              (uaccess, drop the power-switch tag)
  antonixos/hardware-configuration.nix
  xps13/default.nix           laptop specifics (systemd-boot, systemd initrd + resume for
                              the LUKS setup, bluetooth/upower, power mgmt, fwupd,
                              fprintd fingerprint, flatpak for the Bitwarden app)
  xps13/hardware-configuration.nix  also holds the LUKS2 device entries (cryptroot/cryptswap)
  bank/default.nix            server specifics (ZFS `vault`, sanoid, docker, NFS server,
                              tailscale subnet router, sshd, localadm uid/gid 3000, lean HM)
  bank/hardware-configuration.nix
modules/nixos/                shared config, split by concern
  base.nix                    host-agnostic foundation: nix, locale, networking, boot,
                              users, caches + system.stateVersion. ALL hosts get this.
  default.nix                 the desktop/laptop bundle: base.nix + GUI modules below
                              + external flake modules (chaotic, stylix, noctalia-greeter,
                              home-manager). antonixos/xps13 import this; bank does NOT.
                              niri is nixpkgs' own programs.niri module (no flake input).
  nix.nix                     nix daemon settings, GC, allowUnfree, insecure pkgs
  boot.nix                    EFI vars only (bootloader is per-host; quiet/splash boot
                              is desktop-only and lives in desktop.nix)
  locale.nix                  timezone/locale (Europe/Copenhagen, en_DK), console keymap
  networking.nix              NetworkManager, tailscale (bluetooth is per-host; upower
                              is xps13-only)
  network-share.nix           bank's three NFS exports auto-mounted over tailscale under
                              /mnt/vault (desktop bundle only — bank is the server)
  audio.nix                   PipeWire (+rtkit)
  desktop.nix                 niri, greeter, quiet/plymouth boot, fonts, xdg portals,
                              noctalia greeter polkit, kdeconnect (+firewall ports)
  packages.nix                desktop-host packages (incl. the noctalia shell and helium
                              from flake inputs, and a wrapped equibop for the IPU6 webcam)
                              + SUDO_ASKPASS (NOT on bank)
  users.nix                   user `anton` (wheel/video/networkmanager, zsh login shell)
  stylix.nix                  system stylix (catppuccin-mocha, dark)
  caches.nix                  ALL binary substituters/keys (single source of truth)
  home-manager.nix            wires HM into the desktop hosts, threads hostName+inputs
                              to home/ (bank has its own HM block in its host file)
home/
  default.nix                 desktop HM entrypoint: imports programs/*, xdg.userDirs
                              (lowercase), xdg.mimeApps URL-scheme handlers
  bank.nix                    lean HM profile for bank: zsh-headless, nvim, yazi, comma
  programs/
    niri/niri.nix             picks config-<host>.kdl by hostName
    niri/config-antonixos.kdl raw niri config (edited directly, NOT via a Nix settings API)
    niri/config-xps13.kdl
    zsh.nix                   zsh + powerlevel10k + aliases (`update`, `flupdate`,
                              `bupdate`) + the `uc` jellyfin-maintenance function
    zsh-headless.nix          lean zsh for bank (starship prompt; no p10k/lsd/bat/fastfetch)
    nvim.nix                  neovim + lazyvim, defaultEditor
    kitty.nix                 kitty (JetBrainsMono Nerd Font)
    yazi.nix                  yazi file manager + clipboard plugin + keymap
    fastfetch.nix             declarative fastfetch config (hypr preset)
    mpd.nix                   mpd + rmpc, library over NFS from bank; mpDris2 for the
                              media keys (desktop hosts only)
    idle.nix                  swayidle lock/dpms/suspend chain — xps13 only (mkIf hostName)
    comma.nix                 comma (`,`) on the prebuilt nix-index database
    noctalia.nix              noctalia shell settings (bar, dock, theme, wallpaper, session)
    bitwarden.nix             bitwarden desktop (nixpkgs) + SSH agent; antonixos/bank
    bitwarden-flatpak.nix     xps13: bitwarden as a Flatpak (nix-flatpak) for working
                              biometrics; SSH-agent socket pinned to the flatpak data
                              dir. home/default.nix picks one of the two by hostName
    flatpak.nix               shared nix-flatpak policy (update on activation);
                              imported alongside the nix-flatpak HM module
    twintail.nix              antonixos: twintail launcher (Flathub Flatpak)
    sober.nix                 antonixos: sober roblox player (Flathub Flatpak)
    stylix.nix                per-app stylix opt-outs (kitty/noctalia/yazi)
    termfilechooser.nix       file-chooser portal wired to yazi-in-kitty
```

## Build & verify

- Rebuild (interactive): `sudo nixos-rebuild switch --flake ~/nixos-config#<host>`
  (zsh alias `update` targets `#$HOST`).
- **Deploy bank** from a desktop host (bank is headless): zsh alias `bupdate` =
  `nixos-rebuild switch --flake ~/nixos-config#bank --target-host anton@bank
  --use-remote-sudo` — builds locally, copies over Tailscale, activates with
  remote sudo (bank's wheel sudo is passwordless, SSH is key-only).
- **Agent-run rebuild:** use `pkexec` so authentication goes through the GUI
  polkit agent (`polkit-gnome`, started from `modules/nixos/desktop.nix`), whose
  dialog accepts either the password *or* a fingerprint,
  instead of blocking on a dead TTY:
  `setsid pkexec nixos-rebuild switch --flake ~/nixos-config#<host> < /dev/null`.
  The `setsid … < /dev/null` detaches from any controlling TTY so pkexec routes to
  the registered GUI agent rather than a text prompt; the `~` is expanded by the
  caller's shell, so pkexec gets an absolute flake path (it does not preserve cwd).
  Fingerprint auth needs `services.fprintd.enable` + an enrolled finger (xps13
  only). The old `sudo -A` + ksshaskpass path (`SUDO_ASKPASS` in
  `modules/nixos/packages.nix`) still works for other agent commands, but its
  dialog is password-only.
- Eval-only check (no root, no build — use this to validate changes):
  `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
- Parse a single file: `nix-instantiate --parse <file>.nix`.
- Hosts are `antonixos`, `xps13` and `bank`. `$HOST` on each machine matches
  its hostname.

## Where things live (quick index)

- **A niri keybind / window-rule / startup app** → `home/programs/niri/config-<host>.kdl`
  (raw KDL, hand-written — niri comes from nixpkgs' `programs.niri` module, which
  has no config settings API; this file is the whole config).
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
  themselves opt out in `home/programs/stylix.nix` (currently kitty, noctalia and
  yazi — anything noctalia's theme templates write must opt out, or HM activation
  fails on the clobbered file at the next-but-one rebuild).
  noctalia applies its own Catppuccin theme + templates to btop/kitty/niri/neovim/
  obsidian/yazi (see `home/programs/noctalia.nix` `theme.templates`).
- **The file picker** → termfilechooser → yazi in kitty (`home/programs/termfilechooser.nix`
  + portal config in `modules/nixos/desktop.nix`).
- **A URL-scheme / default-app handler** (e.g. `discord://` → equibop) →
  `xdg.mimeApps.defaultApplications` in `home/default.nix`.
- **A udev rule / peripheral access** → `hosts/antonixos/udev.nix` (one file for
  every device on that host, not a file per rule).
- **An idle / lock / suspend timeout** → `home/programs/idle.nix`, which is
  `lib.mkIf (hostName == "xps13")`; the desktop deliberately has no idle chain.
- **A Flatpak app** → its own `home/programs/<app>.nix` with
  `services.flatpak.packages`, imported from the matching `hostName` branch in
  `home/default.nix` (that branch must also pull in the nix-flatpak HM module
  and `./programs/flatpak.nix`). Flatpak-wide policy goes in `flatpak.nix`.

## Host differences

antonixos is the gaming desktop, xps13 the schoolwork laptop, bank the headless
server — place "laptop-ish" things (battery, firmware, fingerprint) in xps13's
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
| Extras      | Steam, gamescope, protontricks, sbctl, nix-ld, QMK/Wooting udev | fprintd fingerprint, Bitwarden via Flatpak, suspend-then-hibernate | ZFS+sanoid, Docker, NFS server, subnet router, sshd |

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
- **Comments describe the config as it is now, not how it got here.** Keep the
  ones that explain current behaviour, a persistent gotcha, or what an option or
  input is for. Drop the story of a change — what broke, what was tried first,
  why it was swapped, the issue link for a problem that is already handled. The
  diff is the record of what changed, and that rationale doesn't get relocated
  into the commit message either; if it's worth keeping it belongs in this file.
  A comment also shouldn't point at unmanaged state outside the repo (an
  imperatively installed app, a path in `$HOME`): describe what the option does,
  not who happens to use it.
- Commit messages are a subject line only (`area: what changed`, lowercase),
  no rationale body.
- Only commit or push when explicitly asked.

## Gotchas already discovered (don't re-derive these)

- **niri keyboard layout is pinned in the KDL** (`input.keyboard.xkb` in each
  `config-<host>.kdl`). With that block empty, niri follows systemd-localed,
  which since systemd 261 no longer reads `/etc/X11/xorg.conf.d/00-keyboard.conf`
  and silently drops the layout to US. Don't remove the xkb block; keep it and
  the host file's `services.xserver.xkb.layout` in agreement.

- **niri is nixpkgs' `programs.niri` module** — there is no niri flake input.
  That module is minimal, so `modules/nixos/desktop.nix` supplies what it leaves
  out:
  - **A polkit authentication agent** — the module ships none, so GUI auth
    prompts (Bitwarden's `com.bitwarden.Bitwarden.unlock` auth_self, any
    `pkexec` needing a prompt) would silently fail. desktop.nix runs
    `polkit-gnome` as a `systemd.user.services` unit (`wantedBy = niri.service`).
    It's the GTK agent on purpose: stylix themes its dialog and it dodges the
    Qt/Kvantum render crash a KDE agent hits under this session.
  - **`hardware.graphics.enable`** — not set by the module. antonixos sets its
    own (NVIDIA); xps13 (Intel) relies on the `lib.mkDefault true` in desktop.nix.
    Don't remove it or xps13 loses GPU accel.
  - **Portal FileChooser** — the module defines `xdg.portal.config.niri` itself
    (and sets FileChooser to gtk because `programs.niri.useNautilus = false`), so
    desktop.nix must `lib.mkForce` the niri FileChooser to `termfilechooser`.
    `wayland-session.nix` (pulled in by the module) already adds the gtk portal
    and enables dconf/polkit/gnome-keyring, so those aren't re-declared.
  Stylix has no niri target, so there is **no** `stylix.targets.niri` opt-out —
  niri is themed by noctalia's templates.

- **noctalia greeter sync** runs `pkexec noctalia-greeter-apply-appearance` on
  every wallpaper/colour change (auto_sync), and its action defaults to
  `auth_admin`. A polkit rule in `modules/nixos/desktop.nix` authorizes it
  without a prompt by matching the action id `org.noctalia.greeter.apply-appearance`
  for the active local wheel session. (noctalia's policy annotates `exec.path`
  with the real store path, so pkexec binds this action by id, not by the
  `org.freedesktop.policykit.exec` fallback.)
  `security.polkit.enablePkexecWrapper = true` is required because nixpkgs made
  the setuid pkexec wrapper opt-in.
- **fastfetch icons** in `home/programs/fastfetch.nix` are written as `\uXXXX`
  escapes, not raw Nerd Font glyphs — the glyphs live in the Private Use Area and
  get silently stripped on edit. The logo uses `type: "kitty-direct"` (plain
  `kitty` needs image libs nixpkgs' fastfetch lacks) and an absolute path (no `~`).
- **SSH agent** is Bitwarden, and the socket path is per-host. antonixos/bank use
  the nixpkgs build's `~/.bitwarden-ssh-agent.sock` (`home/programs/bitwarden.nix`);
  xps13 uses the Flatpak's
  `~/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock`, pinned via a
  `BITWARDEN_SSH_AUTH_SOCK` flatpak override (`home/programs/bitwarden-flatpak.nix`).
  Each file sets `SSH_AUTH_SOCK` + ssh `IdentityAgent` to its own socket.
- **Bitwarden is a Flatpak on xps13, the nixpkgs build elsewhere** —
  `home/default.nix` branches on `hostName`, importing `bitwarden-flatpak.nix`
  (+ the nix-flatpak HM module) for xps13 and `bitwarden.nix` otherwise. Why: the
  nixpkgs build cannot enable biometric unlock — `setKeyForUser` panics on a null
  `clientKeyPartB64` (upstream bitwarden/clients#15790) — while the Flatpak's
  fingerprint unlock (polkit + the gnome-keyring secret service) works.
  Consequences to respect:
  - **The polkit unlock action must be registered.** Biometric unlock — desktop
    *and* browser — authenticates via the polkit action
    `com.bitwarden.Bitwarden.unlock`. The Flatpak can't install a system polkit
    policy itself, and the nixpkgs `bitwarden-desktop` package that ships it is not
    installed on this host, so `hosts/xps13/default.nix` registers it via a
    `writeTextDir` package. Without it, unlock fails "Action
    com.bitwarden.Bitwarden.unlock is not registered".
  - **Never declare `~/.config/autostart/bitwarden.desktop` via home-manager.** It
    lands as a read-only /nix/store symlink; Bitwarden writes that exact path on
    launch (`addOpenAtLogin`) and the resulting EROFS throw happens *before* it
    registers its `messagingService` IPC listener — silently breaking the app menu
    (File collapses to just Quit, no Settings), the account switcher, and the
    SSH-agent handlers. Autostart Bitwarden from niri `spawn-at-startup` in
    `config-<host>.kdl` instead, and keep the app's own "start on login" off.
  - **Firefox extension biometric unlock is wired up by hand** in
    `bitwarden-flatpak.nix` (upstream supports it — IPC transport #14836, sandbox
    biometric fix #18625, ~2026.5 — but the Flatpak doesn't auto-write the browser
    manifest, and its `desktop_proxy` bridge lives inside the sandbox). Three
    parts: (1) the polkit action above; (2) a proxy wrapper (`writeShellScript`)
    that runs `flatpak run --command=/app/Bitwarden/desktop_proxy
    com.bitwarden.desktop`; (3) the native-messaging manifest
    `com.8bit.bitwarden.json` (extension id `{446900e4-71c2-419f-a6a7-df9c091e268b}`)
    pointing at that wrapper. **Manifest location matters**: this nixpkgs Firefox
    (`MOZ_LEGACY_PROFILES=1`) reads it from `~/.mozilla/native-messaging-hosts/`
    even though its profile is the XDG `~/.config/mozilla/firefox` —
    `~/.config/mozilla/native-messaging-hosts` does NOT work.
  - **Linux has no first-unlock-with-biometrics**: after each app start you unlock
    once with master password/PIN, then fingerprint works for the rest of the
    session. Bitwarden autostarts and stays running, so that's once per boot.
- **NFS shares** on the desktop hosts mount bank's exports at
  `/mnt/vault/{data,configs,localadm}` (`modules/nixos/network-share.nix`).
  They are `noauto`/automount over Tailscale — they only mount on access,
  address the server by its MagicDNS name `bank`, and require `tailscaled` up.
  The server side (exports, all_squash to uid/gid 3000) is in `hosts/bank/default.nix`.
- **home-manager wiring is split**: `modules/nixos/home-manager.nix` (desktop
  bundle) points at `home/default.nix`; bank carries its own `home-manager`
  block pointing at the slim `home/bank.nix`. HM settings changed in one place
  won't reach the other.
- **xps13 is LUKS2-encrypted** (root + swap). Both volumes share one
  passphrase: `boot.initrd.systemd.enable`
  (in `hosts/xps13/default.nix`) makes stage-1 retry it on the swap volume, so
  boot shows a single prompt — don't remove that option or the second prompt
  comes back. The initrd prompt uses the `dk-latin1` console keymap from
  `locale.nix`. The UUIDs in `boot.initrd.luks.devices` are the LUKS *container*
  UUIDs; the btrfs UUID in `fileSystems` is the volume inside cryptroot.
  Swap runs through `/dev/mapper/cryptswap` and is also the hibernation resume
  device (`boot.resumeDevice`). Argon2id makes each unlock take a few seconds —
  that's by design, not a hang. The other hosts are unencrypted.
- **URL-scheme handlers** live in `xdg.mimeApps.defaultApplications` in
  `home/default.nix`. Enabling `xdg.mimeApps` makes `~/.config/mimeapps.list` a
  read-only store symlink, so an app cannot self-register a scheme at runtime
  (Electron's `setAsDefaultProtocolClient` silently no-ops). Every scheme the
  session should handle has to be listed there — including the ones an app would
  otherwise claim for itself on first launch (`discord://`, `claude-cli://`,
  the deadlock mod manager's, …).
