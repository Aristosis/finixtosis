{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.zsh;
in
{
  options.programs.zsh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable [zsh](${pkgs.zsh.meta.homepage}) as a system shell.
      '';
    };

    package = lib.mkOption {
      type = lib.types.shellPackage;
      default = pkgs.zsh;
      defaultText = lib.literalExpression "pkgs.zsh";
      description = ''
        The package to use for `zsh`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    environment.shells = [
      "/run/current-system/sw${cfg.package.shellPath}"
      "${cfg.package}${cfg.package.shellPath}"
    ];

    environment.etc."profile.d/zsh.sh".text = ''
      if [ -n "''${zsh_VERSION:-}" ] && [ -r /etc/zshrc ]; then
        . /etc/zshrc
      fi
    '';

    environment.etc.zshenv.text = ''
      # /etc/zshenv: system-wide environment configuration for zsh shells.

      if [ -r /etc/profile ]; then
        . /etc/profile
      fi
    '';

    environment.etc.zshrc.text = ''
      # /etc/zshrc: system-wide configuration for interactive zsh shells.

      # We are not always an interactive shell.
      if [ -n "$PS1" ]; then
        if command -v dircolors >/dev/null; then
          eval "$(dircolors -b)"
        fi

        alias ls='ls --color=auto'
      fi
    '';
  };
}
