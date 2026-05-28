{
  config,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:

let
  sddmTokyoNight = pkgs.callPackage ../../pkgs/sddm-tokyo-night { };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

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

  networking.hostName = "loq15arp9";
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

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "tokyo-night-sddm";
    extraPackages = [ pkgs.kdePackages.qt5compat ];
  };

  # Legacy option name: this selects the NVIDIA driver stack for Wayland too.
  # It does not enable an X11 desktop session.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-hibernate.enable = true;
  systemd.services.nvidia-resume.enable = true;

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
}
