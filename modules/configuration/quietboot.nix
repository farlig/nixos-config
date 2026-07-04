{ pkgs, inputs, ... }:
{
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
}
