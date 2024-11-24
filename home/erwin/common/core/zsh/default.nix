{ pkgs, configVars, ... }:
{
  programs.zsh = {
    enable = true;

    # relative to ~
    dotDir = ".config/zsh";
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    autosuggestion.enable = true;
    history.size = 10000;
    history.share = true;
    loginExtra = ''
      #  wordt uitgevoerd bij het openen van elke nieuwe interactieve shell
      ${pkgs.fastfetch}/bin/neofetch
    '';

    plugins = [
      {
        name = "powerlevel10k-config";
        src = ./p10k;
        file = "p10k.zsh";
      }
      {
        name = "zsh-powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
        file = "powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-term-title";
        src = "${pkgs.zsh-term-title}/share/zsh/zsh-term-title/";
      }
      {
        name = "cd-gitroot";
        src = "${pkgs.cd-gitroot}/share/zsh/cd-gitroot";
      }
      {
        name = "zhooks";
        src = "${pkgs.zhooks}/share/zsh/zhooks";
      }
    ];

    initExtraFirst = ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';

    initExtra = ''
      # autoSuggestions config

      unsetopt correct # autocorrect commands

      setopt hist_ignore_all_dups # remove older duplicate entries from history
      setopt hist_reduce_blanks # remove superfluous blanks from history items
      setopt inc_append_history # save history entries as soon as they are entered

      # auto complete options
      setopt auto_list # automatically list choices on ambiguous completion
      setopt auto_menu # automatically use menu completion
      zstyle ':completion:*' menu select # select completions with arrow keys
      zstyle ':completion:*' group-name "" # group results by category
      zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion

      #      bindkey '^I' forward-word         # tab
      #      bindkey '^[[Z' backward-word      # shift+tab
      #      bindkey '^ ' autosuggest-accept   # ctrl+space

      # bindings
      bindkey -v
      bindkey '^A' beginning-of-line
      bindkey '^E' end-of-line
      bindkey '^H' backward-delete-word
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word

      # kubectl auto-complete
      source <(kubectl completion zsh)

      # open commands in $EDITOR with C-e
      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey "^e" edit-command-line

    '';

    oh-my-zsh = {
      enable = true;
      # Standard OMZ plugins pre-installed to $ZSH/plugins/
      # Custom OMZ plugins are added to $ZSH_CUSTOM/plugins/
      # Enabling too many plugins will slowdown shell startup
      plugins = [
        "git"
        "sudo" # press Esc twice to get the previous command prefixed with sudo https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/sudo
      ];
      extraConfig = ''
        # Display red dots whilst waiting for completion.
        COMPLETION_WAITING_DOTS="true"
      '';
    };

    shellAliases = {
      # Overrides those provided by OMZ libs, plugins, and themes.
      # For a full list of active aliases, run `alias`.



      #-------------Bat related------------
      cat = "bat";
      diff = "batdiff";
      rg = "batgrep";
      man = "batman";

      #------------Navigation------------
      doc = "cd $HOME/Documents";
      scripts = "cd $HOME/scripts";
      src = "cd $HOME/src";
      edu = "cd $HOME/src/edu";
      dfs = "cd $HOME/src/dotfiles";
      dfsw = "cd $HOME/src/dotfiles.wiki";
      nfs = "cd $HOME/nix-config";

      ls = "eza --icons always --git"; # default view
      ll = "eza -bhl --icons --git --group-directories-first"; # long list
      la = "eza -abhl --icons --git --group-directories-first"; # all list
      lt = "eza --tree --level=2 --icons --git"; # tree

      #-------------Neovim---------------
      e = "nvim";
      vi = "nvim";
      vim = "nvim";

      #-----------Nix related----------------
      nfc = "nix flake check";
      ne = "nix instantiate --eval";
      nb = "nix build";
      ns = "nix shell";

      #-------------Git Goodness-------------
      # just reference `$ alias` and use the defautls, they're good.

      # git
      gaa = "git add --all";
      gcam = "git commit --all --message";
      gcl = "git clone";
      gco = "git checkout";
      ggl = "git pull";
      ggp = "git push";

      # kubectl
      k = "kubectl";
      kgno = "kubectl get node";
      kdno = "kubectl describe node";
      kgp = "kubectl get pods";
      kep = "kubectl edit pods";
      kdp = "kubectl describe pods";
      kdelp = "kubectl delete pods";
      kgs = "kubectl get svc";
      kes = "kubectl edit svc";
      kds = "kubectl describe svc";
      kdels = "kubectl delete svc";
      kgi = "kubectl get ingress";
      kei = "kubectl edit ingress";
      kdi = "kubectl describe ingress";
      kdeli = "kubectl delete ingress";
      kgns = "kubectl get namespaces";
      kens = "kubectl edit namespace";
      kdns = "kubectl describe namespace";
      kdelns = "kubectl delete namespace";
      kgd = "kubectl get deployment";
      ked = "kubectl edit deployment";
      kdd = "kubectl describe deployment";
      kdeld = "kubectl delete deployment";
      kgsec = "kubectl get secret";
      kdsec = "kubectl describe secret";
      kdelsec = "kubectl delete secret";

      ld = "lazydocker";
      lg = "lazygit";



    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  #TODO: setting up starship

  # programs.starship = {
  #   enable = true;
  #   catppuccin.enable = true;
  #   enableZshIntegration = true;
  #   settings = {
  #     add_newline = false;
  #     directory = {
  #       style = "bold lavender";
  #     };
  #     aws = {
  #       disabled = true;
  #     };
  #     docker_context = {
  #       symbol = " ";
  #     };
  #     golang = {
  #       symbol = " ";
  #     };
  #     kubernetes = {
  #       disabled = false;
  #       style = "bold pink";
  #       symbol = "󱃾 ";
  #       format = "[$symbol$context( \($namespace\))]($style)";
  #       contexts = [
  #         {
  #           context_pattern = "arn:aws:eks:(?P<var_region>.*):(?P<var_account>[0-9]{12}):cluster/(?P<var_cluster>.*)";
  #           context_alias = "$var_cluster";
  #         }
  #       ];
  #     };
  #     lua = {
  #       symbol = " ";
  #     };
  #     package = {
  #       symbol = " ";
  #     };
  #     php = {
  #       symbol = " ";
  #     };
  #     python = {
  #       symbol = " ";
  #     };
  #     terraform = {
  #       symbol = " ";
  #     };
  #     right_format = "$kubernetes";
  #   };
  # };

}
