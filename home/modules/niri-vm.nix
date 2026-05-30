{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Use the static copy of niri config from the repo
  niriBaseConfig = builtins.readFile ../static/niri-config.kdl;

  # Generate config for VM (same as physical, no debug block needed)
  niriVmConfig = pkgs.writeTextDir "config.kdl" ''
${niriBaseConfig}
'';
in
{
  # Override the niri config for VM only
  # Uses mkForce to override the dotfiles symlink
  xdg.configFile."niri" = lib.mkForce {
    source = niriVmConfig;
    recursive = true;
  };
}
