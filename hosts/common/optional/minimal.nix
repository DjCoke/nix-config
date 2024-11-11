{ lib, ... }:
{
  config.hostSpec.isMinimal = lib.mkForce true;
}
