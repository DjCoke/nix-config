{ config, ... }:
{
  imports = [
    #################### Required Configs ####################
    common/core # required
  ];

  services.yubikey-touch-detector.enable = true;

  home = {
    username = config.hostSpec.username;
    homeDirectory = "/home/${config.hostSpec.username}";
  };
}
