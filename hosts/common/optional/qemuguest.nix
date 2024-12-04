{ pkgs, ... }:
{
  # Adding the QEMU Guest Agent
  services.qemuGuest.enable = true;

}
