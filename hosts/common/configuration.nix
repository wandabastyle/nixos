{
  config,
  lib,
  pkgs,
  ...
}:

let
  sddmTokyoNight = pkgs.callPackage ../../pkgs/sddm-tokyo-night { };
in
{
  # Shared NixOS configuration for loq15arp9 hosts

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "kanashi"
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "btrfs" ];

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };
  console.keyMap = "de";

  users.users.kanashi = {
    isNormalUser = true;
    description = "kanashi";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
    shell = pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;
  programs.dconf.enable = true;

  programs.fish.enable = true;
  programs.niri.enable = true;

  hardware.graphics.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "tokyo-night-sddm";
    extraPackages = [ pkgs.kdePackages.qt5compat ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  environment.systemPackages = with pkgs; [
    sddmTokyoNight
    alsa-utils
    git
    vim
    wget
    curl
    gsettings-desktop-schemas
    hicolor-icon-theme
    pciutils
    usbutils
    wl-clipboard
    xdg-utils
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  system.stateVersion = "25.11";

  # Copy dotfiles and SSH from nixos user (ISO) to kanashi on first boot
  system.activationScripts.copyUserData = {
    deps = [ "users" ];
    text = ''
      # Only run if dotfiles exist in nixos home but not in kanashi home
      if [[ -d /home/nixos/dotfiles ]] && [[ ! -d /home/kanashi/dotfiles ]]; then
        echo "Copying dotfiles from /home/nixos to /home/kanashi..."
        mkdir -p /home/kanashi
        cp -r /home/nixos/dotfiles /home/kanashi/
        chown -R kanashi:users /home/kanashi/dotfiles
      fi

      # Copy SSH config if it exists
      if [[ -d /home/nixos/.ssh ]] && [[ ! -d /home/kanashi/.ssh ]]; then
        echo "Copying SSH config from /home/nixos to /home/kanashi..."
        mkdir -p /home/kanashi
        cp -r /home/nixos/.ssh /home/kanashi/
        chown -R kanashi:users /home/kanashi/.ssh
        chmod 700 /home/kanashi/.ssh
        chmod 600 /home/kanashi/.ssh/id_* 2>/dev/null || true
        chmod 644 /home/kanashi/.ssh/*.pub 2>/dev/null || true
        chmod 644 /home/kanashi/.ssh/config 2>/dev/null || true
        chmod 644 /home/kanashi/.ssh/known_hosts 2>/dev/null || true
      fi
    '';
  };
}
