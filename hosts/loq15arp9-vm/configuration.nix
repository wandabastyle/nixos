{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../common/configuration.nix
    ./hardware-configuration.nix
    (import ../common/disko.nix { device = "/dev/vda"; })
  ];

  # VM hostname
  networking.hostName = "loq15arp9-vm";

  # VM uses modesetting instead of NVIDIA
  services.xserver.videoDrivers = [ "modesetting" ];

  # VM guest agents for better integration
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}
