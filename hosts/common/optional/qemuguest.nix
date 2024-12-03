{ pkgs, ... }:
{
  # Adding the QEMU Guest Agent
  services.qemuGuestAgent.enable = true;

  environment.systemPackages = [
    pkgs.qemuGuestAgent
  ];
}
