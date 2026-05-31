{
  config,
  pkgs,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaShell = pkgs.callPackage ../../pkgs/noctalia-shell-custom {
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
  home.packages = [
    noctaliaShell
    nirinit
    ollamaPackage
  ];

  # Provide quickshell config path for qs -c noctalia-shell compatibility
  # This matches Arch-style where ~/.config/quickshell/noctalia-shell contains the shell.qml
  xdg.configFile."quickshell/noctalia-shell" = {
    source = "${noctaliaShell}/share/noctalia-shell";
    recursive = true;
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
