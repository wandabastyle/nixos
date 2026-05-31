{
  lib,
  stdenvNoCC,
  noctaliaShell,
}: 

stdenvNoCC.mkDerivation {
  pname = "noctalia-shell-custom";
  inherit (noctaliaShell) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    cp -r ${noctaliaShell}/share/noctalia-shell $out/share/noctalia-shell
    chmod -R u+w $out/share/noctalia-shell

    cp ${../../overrides/noctalia-shell/Modules/Bar/Widgets/MediaMini.qml} \
      $out/share/noctalia-shell/Modules/Bar/Widgets/MediaMini.qml

    ln -s ${noctaliaShell}/bin/noctalia-shell $out/bin/noctalia-shell
    
    # Provide qs compatibility for Arch-style launch
    # Try to link to upstream qs/quickshell binary, fallback to wrapper
    if [ -f ${noctaliaShell}/bin/qs ]; then
      ln -s ${noctaliaShell}/bin/qs $out/bin/qs
    elif [ -f ${noctaliaShell}/bin/quickshell ]; then
      ln -s ${noctaliaShell}/bin/quickshell $out/bin/qs
    else
      # Create a wrapper that translates qs -c calls to noctalia-shell
      cat > $out/bin/qs << 'EOF'
#!/usr/bin/env bash
# Wrapper for qs -c compatibility with new noctalia-shell

# Parse arguments: qs -c <config> [ipc call ...]
if [ "$1" = "-c" ]; then
  shift
  CONFIG="$1"
  shift
  
  if [ "$CONFIG" = "noctalia-shell" ]; then
    # Translate to noctalia-shell
    if [ "$1" = "ipc" ] && [ "$2" = "call" ]; then
      # qs -c noctalia-shell ipc call <command>
      shift 2
      exec noctalia-shell ipc call "$@"
    else
      # qs -c noctalia-shell (launch)
      exec noctalia-shell "$@"
    fi
  else
    echo "Unknown config: $CONFIG" >&2
    exit 1
  fi
else
  # Pass through to noctalia-shell
  exec noctalia-shell "$@"
fi
EOF
      chmod +x $out/bin/qs
    fi

    runHook postInstall
  '';

  meta = noctaliaShell.meta // {
    description = "Noctalia shell with local MediaMini override and qs compatibility";
    mainProgram = "noctalia-shell";
  };
}
