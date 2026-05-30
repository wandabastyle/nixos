{ lib, ... }:

{
  # VM-specific hardware configuration
  # This replaces the physical laptop hardware-config for QEMU/KVM VMs

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
    "virtio_gpu"
    "9p"
    "9pnet_virtio"
    "xhci_pci"
    "usb_storage"
    "sr_mod"
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # No firmware needed in VM
  hardware.enableRedistributableFirmware = lib.mkDefault false;

  # Generic x86_64 for VM
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
