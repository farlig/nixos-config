{ config, pkgs, hostName, ... }:

{
  xdg.configFile."niri/config.kdl".source = 
  if hostName == "antonixos"
    then ./config-antonixos.kdl
    else ./config-xps13.kdl;
}  
