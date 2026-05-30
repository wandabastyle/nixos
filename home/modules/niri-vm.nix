{
  config,
  lib,
  pkgs,
  ...
}:

{
  # VM niri config - now using the same static config as physical host
  # since virtio GPU with DRM is available (via egl-headless on NVIDIA host)
  xdg.configFile."niri/config.kdl".source = ../static/niri-config.kdl;
}
