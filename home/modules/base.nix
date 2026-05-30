{
  config,
  lib,
  pkgs,
  inputs,
  unstablePkgs,
  ...
}:

{
  home.packages = [
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
    pkgs.gnupg
    pkgs.pinentry-curses
    pkgs.gtk3
    pkgs.gtk4
    pkgs.libsForQt5.qt5ct
    pkgs.papirus-icon-theme
    pkgs.imagemagick
    pkgs.jq
    pkgs.lazygit
    pkgs.pass
    pkgs.mpv
    pkgs.neovim
    pkgs.nodejs
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

  xdg.enable = true;

  home.sessionVariables = {
    GTK_THEME = "Tokyonight-Dark";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
  };

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

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    enableSshSupport = true;
  };
}
