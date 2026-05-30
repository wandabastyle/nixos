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
    (import ../common/disko.nix { device = "/dev/nvme0n1"; })
  ];

  # Physical laptop hostname
  networking.hostName = "loq15arp9";

  # NVIDIA proprietary driver for RTX 4060 Laptop
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-hibernate.enable = true;
  systemd.services.nvidia-resume.enable = true;
}
