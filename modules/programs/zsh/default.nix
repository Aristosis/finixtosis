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

    # NOTE: zsh in nixpkgs is compiled with `SYS_ZSHRC="/etc/zshrc"` which means:
    # - interactive non-login shells source this automatically
    # - login shells get it via the profile.d drop-in above
    environment.etc.zshrc.text = ''
      # /etc/zshrc: system-wide configuration for interactive zsh shells.

      # We are not always an interactive shell.
      if [ -n "$PS1" ]; then
        # Check the window size after every command.
        shopt -s checkwinsize

        # Disable hashing (i.e. caching) of command lookups.
        set +h

        # Provide a nice prompt if the terminal supports it.
        if [ "$TERM" != "dumb" ] || [ -n "$INSIDE_EMACS" ]; then
          PROMPT_COLOR="1;31m"
          ((UID)) && PROMPT_COLOR="1;32m"
          if [ -n "$INSIDE_EMACS" ]; then
            # Emacs term mode doesn't support xterm title escape sequence (\e]0;)
            PS1="\n\[\033[$PROMPT_COLOR\][\u@\h:\w]\\$\[\033[0m\] "
          else
            PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "
          fi
          if test "$TERM" = "xterm"; then
            PS1="\[\033]2;\h:\u:\w\007\]$PS1"
          fi
        fi

        if command -v dircolors >/dev/null; then
          eval "$(dircolors -b)"
        fi

        alias ls='ls --color=auto'
      fi
    '';
  };
}
