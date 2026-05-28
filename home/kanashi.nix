{
  config,
  lib,
  pkgs,
  inputs,
  unstablePkgs,
  ...
}:

let
  dotfilesRepo = "${config.home.homeDirectory}/dotfiles";
  dotConfigDir = ../.config;
  dotConfigEntries = builtins.readDir dotConfigDir;
  linkableConfigDirs = lib.filterAttrs (
    name: type: type == "directory" && name != "systemd"
  ) dotConfigEntries;

  mkConfigLink = name: _type: {
    inherit name;
    value.source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/.config/${name}";
  };

  system = pkgs.stdenv.hostPlatform.system;
  noctaliaShell = pkgs.callPackage ../pkgs/noctalia-shell-custom {
    noctaliaShell = inputs.noctalia.packages.${system}.default;
  };
  nirinit = inputs.nirinit.packages.${system}.default;
  ollamaPackage = pkgs.ollama-cuda;

  updatesCounter = pkgs.writeShellScript "updates-counter" ''
    set -u

    repo="$HOME/dotfiles"
    cache="$HOME/.cache/updates-count"
    tmp="$(${pkgs.coreutils}/bin/mktemp -d)"
    cleanup() {
      ${pkgs.coreutils}/bin/rm -rf "$tmp"
    }
    trap cleanup EXIT

    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.cache"

    if [ ! -f "$repo/flake.lock" ]; then
      ${pkgs.coreutils}/bin/printf '0\n' > "$cache"
      exit 0
    fi

    if ${pkgs.nix}/bin/nix flake update --flake "$repo" --output-lock-file "$tmp/flake.lock" >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq -n \
        --slurpfile old "$repo/flake.lock" \
        --slurpfile new "$tmp/flake.lock" \
        '[($old[0].nodes | keys[]) as $k | select(($old[0].nodes[$k].locked // null) != ($new[0].nodes[$k].locked // null))] | length' \
        > "$cache"
    else
      ${pkgs.coreutils}/bin/printf '0\n' > "$cache"
    fi
  '';
in
{
  home.username = "kanashi";
  home.homeDirectory = "/home/kanashi";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  xdg.enable = true;

  home.packages = [
    noctaliaShell
    nirinit
    unstablePkgs.niriswitcher

    pkgs.bat
    pkgs.brave
    pkgs.brightnessctl
    pkgs.cliphist
    pkgs.discord
    pkgs.easyeffects
    pkgs.eza
    pkgs.fd
    pkgs.fish
    pkgs.gh
    pkgs.ghostty
    pkgs.git
    pkgs.gtk3
    pkgs.gtk4
    pkgs.libsForQt5.qt5ct
    pkgs.papirus-icon-theme
    pkgs.imagemagick
    pkgs.jq
    pkgs.lazygit
    pkgs.mpv
    pkgs.neovim
    pkgs.nodejs
    ollamaPackage
    pkgs.pamixer
    pkgs.pavucontrol
    pkgs.pcmanfm
    pkgs.playerctl
    pkgs.python3
    pkgs.ripgrep
    pkgs.rofi
    pkgs.rustup
    pkgs.swayidle
    pkgs.tmux
    pkgs.wl-clipboard
    pkgs.wlsunset
    pkgs.xdg-utils
    pkgs.zoxide
    pkgs.starship
    pkgs.tokyonight-gtk-theme
    pkgs.qt6Packages.qt6ct

    pkgs.gcc
    pkgs.gnumake
    pkgs.pkg-config
  ];

  xdg.configFile = lib.mapAttrs' mkConfigLink linkableConfigDirs;

  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Tokyonight-Dark";
    icon-theme = "Adwaita";
  };

  home.sessionVariables = {
    GTK_THEME = "Tokyonight-Dark";
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  systemd.user.services.nirinit = {
    Unit = {
      Description = "nirinit session restore for niri";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${nirinit}/bin/nirinit --save-interval 300";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.ollama = {
    Unit.Description = "Ollama Server";
    Service = {
      ExecStart = "${ollamaPackage}/bin/ollama serve";
      Environment = "OLLAMA_HOST=0.0.0.0:11434";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.ollama-stop = {
    Unit.Description = "Stop Ollama";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user stop ollama.service";
    };
  };

  systemd.user.timers.ollama-stop = {
    Unit.Description = "Stop Ollama after idle delay";
    Timer = {
      OnActiveSec = "15min";
      Unit = "ollama-stop.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.updates-counter = {
    Unit.Description = "Count available Nix flake updates";
    Service = {
      Type = "oneshot";
      ExecStart = "${updatesCounter}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.timers.updates-counter = {
    Unit.Description = "Run updates counter 4 times a day";
    Timer = {
      OnBootSec = "5min";
      OnCalendar = "*-*-* 0/6:00:00";
      Persistent = true;
      Unit = "updates-counter.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
