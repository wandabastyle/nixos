{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "tokyo-night-sddm-local";
  version = "local";

  src = ../../assets/sddm/tokyo-night-sddm;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sddm/themes/tokyo-night-sddm
    cp -r . $out/share/sddm/themes/tokyo-night-sddm

    runHook postInstall
  '';
}
