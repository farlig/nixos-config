{ ... }:

# Peripheral device access for antonixos. Add new devices here rather than
# spinning up a new file per rule.
{
  # QMK/VIA keyboards (incl. the FLX Virgo). This ships QMK's udev rules, whose
  # catch-all `KERNEL=="hidraw*" ... TAG+="uaccess"` grants the active session
  # raw-HID access to *any* QMK/VIA board — so usevia.app (WebHID, chromium
  # only) works for new keyboards without touching config — plus the bootloader
  # rules for flashing firmware. No per-device rule needed.
  hardware.keyboard.qmk.enable = true;

  services.udev.extraRules = ''
    # Wooting keyboard: expose to user space and stop logind treating its extra
    # keyboard interface as a power switch. (Not QMK — needs its own rule.)
    SUBSYSTEM=="input", ENV{ID_VENDOR_ID}=="31e3", ENV{ID_MODEL_ID}=="1512", ENV{ID_USB_INTERFACE_NUM}=="03", ENV{ID_INPUT_KEYBOARD}="1", TAG-="power-switch", TAG+="uaccess"
  '';
}
