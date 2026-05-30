{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotfilesRepo = "${config.home.homeDirectory}/dotfiles";

  gitmodulesContent = builtins.readFile ../../.gitmodules;
  submoduleParts = lib.splitString "[submodule \".config/" gitmodulesContent;
  allConfigDirs = lib.filter (n: n != null && n != "") (
    map (
      part:
      let
        quoteIdx = lib.findFirst (i: builtins.substring i 1 part == "\"") (lib.stringLength part) (
          lib.genList (i: i) (lib.stringLength part)
        );
      in
      if quoteIdx == lib.stringLength part then null else builtins.substring 0 quoteIdx part
    ) (lib.tail submoduleParts)
  );

  # Filter out systemd (managed declaratively by Home Manager)
  linkableConfigDirs = lib.filter (name: name != "systemd") allConfigDirs;

  mkConfigLink = name: {
    inherit name;
    value.source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/.config/${name}";
  };
in
{
  xdg.configFile = lib.listToAttrs (map mkConfigLink linkableConfigDirs);
}
