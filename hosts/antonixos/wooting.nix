{ ... }:

{
  services.udev.extraRules = ''
    SUBSYSTEM=="input", ENV{ID_VENDOR_ID}=="31e3", ENV{ID_MODEL_ID}=="1512", ENV{ID_USB_INTERFACE_NUM}=="03", ENV{ID_INPUT_KEYBOARD}="1", TAG-="power-switch", TAG+="uaccess"
  '';
}
