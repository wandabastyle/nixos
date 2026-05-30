{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "tokyo-night-sddm-local";
  version = "local";

  src = ../../assets/sddm/tokyo-night-sddm;
  background = ../../assets/sddm/wp6265738.png;

  installPhase = ''
    runHook preInstall

    themeDir=$out/share/sddm/themes/tokyo-night-sddm
    mkdir -p $themeDir
    cp -r . $themeDir

    cp $background $themeDir/Backgrounds/wp6265738.png
    substituteInPlace $themeDir/theme.conf \
      --replace 'Background="Backgrounds/tokyocity.png"' 'Background="Backgrounds/wp6265738.png"'

    runHook postInstall
  '';
}
