# IMPORTANT: This is used by NixOS and nix-darwin so options must exist in both!
{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  pkgs-unstable,
  configLib,
  isDarwinFlag,
  ...
}:
let

  #FIXME: primaryUser* bindings should ideally be assigned values elsewhere but are needed for imports instead of using hostSpec to avoid infinite recursion
  primaryUser = "ta";
  primaryUserHandle = "emergentmind";
  homeDirectory = config.hostSpec.home;

  #FIXME: use conditional value
  #platform = "nixos";
  platform = if isDarwinFlag then "darwin" else "nixos";

in
{
  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "modules/common"
      "modules/${platform}"
      "hosts/common/core/${platform}.nix"
      "hosts/common/core/sops.nix"
      "hosts/common/users/${primaryUser}"
      "hosts/common/users/${primaryUser}/${platform}.nix"
    ])
    inputs.home-manager.nixosModules.home-manager
  ];

  #
  # ========== Core Host Specifications ==========
  #
  hostSpec = {
    username = primaryUser;
    handle = primaryUserHandle;
    inherit (inputs.nix-secrets)
      domain
      email
      userFullName
      networking
      ;
  };

  networking.hostName = config.hostSpec.hostName;
  hardware.enableRedistributableFirmware = true;

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

  # This should be handled by config.security.pam.sshAgentAuth.enable
  security.sudo.extraConfig = ''
    Defaults lecture = never # rollback results in sudo lectures after each reboot, it's somewhat useless anyway
    Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
    Defaults timestamp_timeout=120 # only ask for password every 2h
    # Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
    Defaults env_keep+=SSH_AUTH_SOCK
  '';

  #
  # ========== Nix Nix Nix ==========
  #
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # See https://jackson.dev/post/nix-reasonable-defaults/
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000; # 128MB
      max-free = 1000000000; # 1GB

      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  nixpkgs = {
    # you can add global overlays here
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  #
  # ========== Localization ==========
  #
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  time.timeZone = lib.mkDefault "America/Edmonton";

  #
  # ========== Nix Helper ==========
  #
  # Provide better build output and will also handle garbage collection in place of standard nix gc (garbace collection)
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 20d --keep 20";
    flake = "${homeDirectory}/nix-config";
  };

  #
  # ========== Basic Shell Enablement ==========
  #
  # On darwin it's important this is outside home-manager
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    promptInit = "source ''${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };
}
