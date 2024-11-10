{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  pkgs-unstable,
  configLib,
  ...
}:
let
  homeDirectory = config.hostSpec.home;
in
{
  imports = lib.flatten [
    (configLib.scanPaths ./.)
    (configLib.relativeToRoot "hosts/common/users/${config.hostSpec.username}")
    (configLib.relativeToRoot "modules/common")
    (configLib.relativeToRoot "modules/nixos")
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.extraSpecialArgs = {
    inherit
      pkgs
      pkgs-unstable
      inputs
      configLib
      ;
    # Pass in shared options values
    hostSpec = config.hostSpec;
  };

  networking.hostName = config.hostSpec.hostName;

  hostSpec = {
    username = "ta";
    handle = "emergentmind";
    inherit (inputs.nix-secrets)
      domain
      email
      userFullName
      networking
      ;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 20d --keep 20";
    flake = "${homeDirectory}/nix-config";
  };

  # This should be handled by config.security.pam.sshAgentAuth.enable
  security.sudo.extraConfig = ''
    Defaults lecture = never # rollback results in sudo lectures after each reboot, it's somewhat useless anyway
    Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
    Defaults timestamp_timeout=120 # only ask for password every 2h
    # Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
    Defaults env_keep+=SSH_AUTH_SOCK
  '';

  nixpkgs = {
    # you can add global overlays here
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  hardware.enableRedistributableFirmware = true;
}
