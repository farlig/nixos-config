{ lib, hostName, ... }:

# Idle chain for the laptop: lock at 5 min, screens off at 10, suspend at 20
# (battery only — plugged in it stays awake, matching lid-close-on-AC = lock
# in hosts/xps13/default.nix). noctalia's caffeine toggle is an idle inhibitor
# and pauses all of this. The desktop deliberately has no idle handling.
lib.mkIf (hostName == "xps13") {
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "noctalia msg session lock";
      }
      {
        timeout = 600;
        command = "niri msg action power-off-monitors";
        resumeCommand = "niri msg action power-on-monitors";
      }
      {
        timeout = 1200;
        command = "sh -c 'grep -q 0 /sys/class/power_supply/AC*/online && systemctl suspend-then-hibernate'";
      }
    ];
    events = {
      # Any suspend (lid, idle timeout, session menu) locks first, so resume
      # always lands on the lockscreen.
      before-sleep = "noctalia msg session lock";
      # Handle logind's lock signal, so HandleLidSwitchExternalPower=lock and
      # `loginctl lock-session` work without relying on noctalia subscribing
      # to it itself.
      lock = "noctalia msg session lock";
    };
  };
}
