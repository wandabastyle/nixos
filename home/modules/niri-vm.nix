{
  config,
  pkgs,
  lib,
  ...
}:

{
  # For VM: Append debug block to disable direct scanout
  # This works by using home.file instead of copying the submodule
  home.file.".config/niri/config.kdl".text = lib.mkAfter ''

debug {
    disable-direct-scanout
}
'';
}
