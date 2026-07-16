{ pkgs, inputs, ... }:

# The graphical session shared by all hosts: niri, its greeter, the file-chooser
# portal, fonts and the login shell.
{
  programs.niri.enable = true;

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

  # Authorize that one helper without a prompt. Two reasons a prompt is both
  # unwanted and broken here:
  #   1. The KDE polkit agent (niri-flake-polkit.service) segfaults rendering
  #      its dialog under stylix's Kvantum QQC2 style ("module kvantum is not
  #      installed"), so no auth dialog ever appears — the sync just fails.
  #   2. The helper's own policy (org.noctalia.greeter.apply-appearance) never
  #      binds: its exec.path annotation is the bare name while pkexec matches
  #      the resolved path, so pkexec falls back to org.freedesktop.policykit.exec.
  # Match that fallback action on the resolved program path. The helper only
  # copies the user's own appearance into the greeter state dir, so granting it
  # to the active local wheel session is low risk and makes auto_sync automatic.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          action.lookup("program") &&
          action.lookup("program").indexOf("noctalia-greeter-apply-appearance") !== -1 &&
          subject.active && subject.local && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Fix the segfault described above at its root, rather than working around it.
  # The agent inherits QT_STYLE_OVERRIDE=kvantum from the session and dies while
  # rendering its dialog, so any action needing a real prompt (e.g. Bitwarden's
  # auth_self com.bitwarden.Bitwarden.unlock) just fails to authenticate. Unit
  # Environment= wins over the manager environment, so this unstyles the agent
  # alone and leaves Kvantum in place everywhere else.
  # Known wart: the dialog renders in a light palette. The agent is Qt6 while
  # qt.platformTheme is session-wide "qt5ct", which no Qt6 app can load, so it
  # gets no platform theme and falls back to Fusion's default light colours.
  # Pointing it at qt6ct (which has the dark stylix palette) did not fix it.
  systemd.user.services.niri-flake-polkit.environment.QT_STYLE_OVERRIDE = "Fusion";

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-termfilechooser
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common."org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
      niri = {
        # gnome/gtk fallback so screen recording etc. works. Needed on every
        # host, so it lives here rather than being duplicated per-machine.
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
      };
    };
  };
}
