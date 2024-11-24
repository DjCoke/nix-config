{ configVars, ... }:
{
  imports = [
    #################### Required Configs ####################
    common/core # required
  ];

  home = {
    username = configVars.username;
    homeDirectory = "/home/${configVars.username}";
  };
}
