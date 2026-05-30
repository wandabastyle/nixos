{
  config,
  pkgs,
  lib,
  ...
}:

let
  niriVmConfig = pkgs.runCommand "niri-vm-config" { } ''
    mkdir -p $out
    cp -r ${../../.config/niri}/* $out/
    chmod -R u+w $out
    
    # Append the debug block to disable direct scanout in VMs
    cat >> $out/config.kdl <<'EOF'

debug {
    disable-direct-scanout
}
EOF
  '';
in
{
  # Override the niri config to use the generated one with debug options
  xdg.configFile."niri" = lib.mkForce {
    source = niriVmConfig;
    recursive = true;
  };
}
