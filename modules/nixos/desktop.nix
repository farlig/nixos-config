{ pkgs, inputs, ... }:

# The graphical session shared by all hosts: niri, its greeter, the file-chooser
# portal, fonts and the login shell.
{
  programs.niri.enable = true;

  programs.zsh.enable = true;

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
