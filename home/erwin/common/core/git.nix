{ pkgs
, lib
, config
, configLib
, configVars
, ...
}:
let
  handle = configVars.handle;
  publicGitEmail = configVars.gitHubEmail;
  username = configVars.username;
in
{
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = handle;
    userEmail = publicGitEmail;
    aliases = { };
    #TODO: catpuccin: When this config works, I will get catppuccin to work

    # delta = {
    #   enable = true;
    #   catppuccin.enable = true;
    #   options = {
    #     keep-plus-minus-markers = true;
    #     light = false;
    #     line-numbers = true;
    #     navigate = true;
    #     width = 280;
    #   };
    # };

    extraConfig = {
      log.showSignature = "true";
      init.defaultBranch = "main";
      pull.rebase = "true";
      url = {
        "ssh://git@github.com" = {
          insteadOf = "https://github.com";
        };
        "ssh://git@gitlab.com" = {
          insteadOf = "https://gitlab.com";
        };
      };

    };
    ignores = [
      ".csvignore"
      ".direnv"
      "result"
    ];
  };
  # NOTE: To verify github.com update commit signatures, you need to manually import
  # https://github.com/web-flow.gpg... would be nice to do that here
}