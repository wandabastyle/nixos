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

    runHook postInstall
  '';

  meta = noctaliaShell.meta // {
    description = "Noctalia shell with local MediaMini override";
    mainProgram = "noctalia-shell";
  };
}
