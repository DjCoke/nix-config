# Add your reusable home-manager modules to this directory, on their own file (https://wiki.nixos.org/wiki/NixOS_modules).
# These are modules you would share with others, not your personal configurations.

#{
#  copyq = import ./copyq.nix;
#  monitors = import ./monitors.nix;
#  yubikey-touch-detector = import ./yubikey-touch-detector.nix;
#}
{ configLib, ... }:
{
  imports = configLib.scanPaths ./.;
}
