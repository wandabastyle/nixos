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

  # Software rendering fallback for VMs (helps when virtio GPU acceleration isn't fully working)
  environment.sessionVariables = {
    LIBGL_ALWAYS_SOFTWARE = "1";
    MESA_LOADER_DRIVER_OVERRIDE = "llvmpipe";
  };

  # VM guest agents for better integration
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}
