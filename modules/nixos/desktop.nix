{ pkgs, inputs, lib, ... }:

# The graphical session shared by all hosts: niri, its greeter, the file-chooser
# portal, fonts and the login shell.
{
  imports = [ inputs.umbriel.nixosModules.default ];

  programs.niri.enable = true;

  # Umbriel is a second, selectable session alongside niri — niri stays the
  # greeter default. Its module registers the session, installs the compositor
  # and wires the portal; the per-user config lives in home/programs/umbriel.
  programs.umbriel = {
    enable = true;
    portalPackage =
      inputs.xdg-desktop-portal-umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  # The noctalia greeter reads its session list from
  # /run/current-system/sw/share/wayland-sessions, which nothing links here —
  # services.displayManager isn't in play, greetd is. Without this the greeter
  # has only its --session default and Umbriel can't be picked.
  environment.pathsToLink = [ "/share/wayland-sessions" ];

  # We run our own file chooser (termfilechooser, below) and don't want the
  # nautilus portal dependency pulled in.
  programs.niri.useNautilus = false;

  # The niri module doesn't enable the GPU stack. xps13 (Intel) relies on this;
  # antonixos overrides it with its own explicit hardware.graphics block.
  hardware.graphics.enable = lib.mkDefault true;

  # Phone integration (clipboard/files/notifications) over the LAN — no
  # bluetooth involved. Opens TCP+UDP 1714-1764 in the firewall. The tray
  # indicator is spawned from each host's niri config.
  programs.kdeconnect.enable = true;

  # Quiet, graphical boot (was in the shared boot.nix; the headless server
  # keeps a plain verbose console instead).
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "vt.global_cursor_default=0"
  ];
  boot.plymouth.enable = true;

  fonts.enableDefaultPackages = lib.mkDefault true;
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # Fallbacks so emoji and CJK render instead of tofu boxes.
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];

  programs.noctalia-greeter = {
    enable = true;
    package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
    greeter-args = "--session niri-session";
  };

  # noctalia's "sync wallpaper/colors to greeter" runs
  # `pkexec noctalia-greeter-apply-appearance` to copy the staged appearance
  # into /var/lib/noctalia-greeter. nixpkgs made the setuid pkexec wrapper
  # opt-in, so without this pkexec can't switch users at all.
  security.polkit.enablePkexecWrapper = true;

  # Authorize the greeter appearance-sync without a prompt. noctalia's auto_sync
  # runs `pkexec noctalia-greeter-apply-appearance` on every wallpaper/colour
  # change, and its action defaults to auth_admin — so it prompts each time. The
  # helper only copies the user's own appearance into the greeter state dir, so
  # granting it to the active local wheel session is low risk. noctalia's policy
  # annotates exec.path with the real store path, so pkexec binds this action by
  # id (not the org.freedesktop.policykit.exec fallback) — match it directly.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.noctalia.greeter.apply-appearance" &&
          subject.active && subject.local && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # PolicyKit authentication agent for the niri session. nixpkgs' niri module
  # ships no agent, so GUI auth prompts (e.g. Bitwarden's auth_self
  # com.bitwarden.Bitwarden.unlock) need one running in the session. polkit-gnome
  # is GTK, so stylix themes its dialog and it avoids the Qt/Kvantum rendering
  # crash a KDE agent hits under this session's Kvantum style.
  systemd.user.services.polkit-gnome = {
    description = "polkit-gnome authentication agent";
    wantedBy = [ "niri.service" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # The niri module already sets config.niri.default = [ "gnome" "gtk" ] and adds
  # the gnome/gtk portals; it also points niri's FileChooser at gtk (because
  # useNautilus is off), so force that one back to our terminal file chooser.
  # xdg-desktop-portal-umbriel ships its own config the same way, so the umbriel
  # session needs the identical override.
  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];
    config = {
      common."org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
      niri."org.freedesktop.impl.portal.FileChooser" = lib.mkForce "termfilechooser";
      umbriel."org.freedesktop.impl.portal.FileChooser" = lib.mkForce "termfilechooser";
    };
  };
}
