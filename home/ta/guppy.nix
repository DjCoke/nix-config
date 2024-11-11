{ ... }:
{
  imports = [
    #################### Required Configs ####################
    common/core # required
  ];

  services.yubikey-touch-detector.enable = true;
}
