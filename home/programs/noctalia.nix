{ inputs, hostName, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;

    settings = {
      bar.default = {
        end = [ "privacy" "tray" "notifications" "clipboard" "volume" "brightness" "battery" "session" ];
        margin_ends = 12;
        margin_edge = 12;
        start = [ "workspaces" "wallpaper" "media" "cpu" ];
      };

      backdrop.enable = true;
      backdrop.enabled = true;

      control_center.shortcuts = [
        { type = "caffeine"; }
        { type = "nightlight"; }
        { type = "notification"; }
        { type = "power_profile"; }
        { type = "mic_mute"; }
        { type = "system"; }
      ];

      desktop_widgets = {
        enabled = false;
        schema_version = 2;
        widget_order = [ ];

        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };

        widget = { };
      };

      dock = {
        auto_hide = true;
        enabled = true;
        launcher_position = "start";
        pinned = [ "equibop" "firefox" ];
        reserve_space = false;
        show_dots = true;
      };

      location.address = "Aalborg, Denmark";

      lockscreen.fingerprint = false;

      lockscreen_widgets = {
        enabled = false;
        schema_version = 2;
        widget_order = [ "lockscreen-login-box@DP-1" ];

        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };

        widget."lockscreen-login-box@DP-1" = {
          box_height = 0.0;
          box_width = 0.0;
          cx = 1720.0;
          cy = 1317.0;
          output = "DP-1";
          rotation = 0.0;
          type = "login_box";

          settings = {
            background_color = "surface_variant";
            background_opacity = 0.88;
            background_radius = 12.0;
            input_opacity = 1.0;
            input_radius = 6.0;
            show_login_button = true;
          };
        };
      };

      osd.kinds.media = false;

      shell = {
        avatar_path = "~/pictures/pfps/7dba775efcddd747ccd2717152fa6212.png";

        launcher.compact = true;

        greeter_sync.auto_sync = true;
        greeter_sync.privilege_command = "kitty -e pkexec";

        panel = {
          transparency_mode = "glass";
          wallpaper_position = "center";
        };

        session.actions = [
          { action = "lock"; countdown_seconds = 0.0; enabled = true; shortcut = "1"; variant = "default"; }
          { action = "logout"; countdown_seconds = 0.0; enabled = true; shortcut = "2"; variant = "default"; }
          { action = "lock_and_suspend"; countdown_seconds = 0.0; enabled = true; shortcut = "3"; variant = "default"; }
          { action = "reboot"; countdown_seconds = 0.0; enabled = true; shortcut = "4"; variant = "default"; }
          { action = "shutdown"; countdown_seconds = 0.0; enabled = true; shortcut = "5"; variant = "destructive"; }
          {
            action = "command";
            command = "systemctl reboot --firmware-setup";
            countdown_seconds = 0.0;
            enabled = true;
            label = "Reboot to UEFI";
            variant = "default";
          }
        ];
      };

      theme = {
        builtin = "Catppuccin";
        mode = "dark";
        source = "builtin";

        templates = {
          builtin_ids = [ "btop" "kitty" "niri" ];
          community_ids = [ "neovim" "obsidian" "yazi" ];
        };
      };

      wallpaper = {
        directory = "~/pictures/wallpapers";
        directory_dark = "~/pictures/wallpapers";
        directory_light = "~/pictures/wallpapers";
        enabled = true;

        default.path = "~/pictures/wallpapers/fp6l6u881lod1.jpeg";
        last.path = "~/pictures/wallpapers/fp6l6u881lod1.jpeg";
      };

      widget.network.show_label = false;
      widget.privacy.hide_inactive = true;
      widget.sysmon.stat = "ram_used";

      widget.tray = {
        drawer = true;
        hidden = [ "equibop" "spotify" ];
        pinned = [ "proton.vpn.app.gtk" ];
      };
    };
  };
}
