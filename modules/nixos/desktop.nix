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
  # opt-in, so without this the sync fails with "pkexec must be setuid root"
  # and the greeter keeps its stale wallpaper.
  security.polkit.enablePkexecWrapper = true;

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
