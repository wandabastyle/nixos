{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Use the static copy of niri config from the repo
  niriBaseConfig = builtins.readFile ../static/niri-config.kdl;
  
  # Generate config with debug block appended for VM
  niriVmConfig = pkgs.writeTextDir "config.kdl" ''
${niriBaseConfig}

debug {
    disable-direct-scanout
}
'';
in
{
  # Override the niri config for VM only
  xdg.configFile."niri" = lib.mkForce {
    source = niriVmConfig;
    recursive = true;
  };
}
