# Common disko configuration for loq15arp9 hosts
# Usage: import with device path: (import ../common/disko.nix { device = "/dev/nvme0n1"; })

{ device }:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "2G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              extraArgs = [
                "-F"
                "32"
                "-n"
                "NIXBOOT"
              ];
              mountOptions = [ "umask=0077" ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "NIXROOT"
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "ssd"
                    "discard=async"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "ssd"
                    "discard=async"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "ssd"
                    "discard=async"
                  ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "ssd"
                    "discard=async"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
