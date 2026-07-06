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
