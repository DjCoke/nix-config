{
  config,
  configVars,
  configLib,
  lib,
  ...
}:
let
  yubikeyHosts = [ "guppy" ]; # I do not use yubikeys, but I leave this to be able to build it
  # add my domain to each yubikey host
  yubikeyDomains = map (h: "${h}.${configVars.domain}") yubikeyHosts;
  yubikeyHostAll = yubikeyHosts ++ yubikeyDomains;
  yubikeyHostsString = lib.concatStringsSep " " yubikeyHostAll;

  pathtokeys = configLib.relativeToRoot "hosts/common/users/${configVars.username}/keys";
  yubikeys =
    lib.lists.forEach (builtins.attrNames (builtins.readDir pathtokeys))
      # Remove the .pub suffix
      (key: lib.substring 0 (lib.stringLength key - lib.stringLength ".pub") key);
  yubikeyPublicKeyEntries = lib.attrsets.mergeAttrsList (
    lib.lists.map
      # list of dicts
      (key: { ".ssh/${key}.pub".source = "${pathtokeys}/${key}.pub"; })
      yubikeys
  );

  identityFiles = [
    # "id_yubikey" I do not use yubikeys
    # This is an auto symlink to whatever yubikey is plugged in. See modules/common/yubikey
    "id_erwin" # fallback to id_manu if yubikeys are not present
    "id_github"
  ];

  # Lots of hosts have the same default config, so don't duplicate
  vanillaHosts = [
    "k3s-01"
    "k3s-02"
    "k3s-03"
    "k3s-04"
    "k3s-05"
    "k3s-06"
    "k3s-07"
    "k3s-08"
    "k3s-09"
  ];
  vanillaHostsConfig = lib.attrsets.mergeAttrsList (
    lib.lists.map (host: {
      "${host}" = lib.hm.dag.entryAfter [ "yubikey-hosts" ] {
        host = host;
        hostname = "${host}.${configVars.domain}";
        port = configVars.networking.ports.tcp.ssh;
        identityFile = lib.lists.forEach identityFiles (file: "${config.home.homeDirectory}/.ssh/${file}");
      };
    }) vanillaHosts
  );
in
{
  programs.ssh = {
    enable = true;

    # FIXME:(ssh) This should probably be for git systems only?
    controlMaster = "auto";
    controlPath = "~/.ssh/sockets/S.%r@%h:%p";
    controlPersist = "10m";

    # req'd for enabling yubikey-agent
    extraConfig = ''
      AddKeysToAgent yes
    '';

    matchBlocks = {
      # Not all of this systems I have access to can use yubikey.
      "yubikey-hosts" = lib.hm.dag.entryAfter [ "*" ] {
        host = "${yubikeyHostsString}";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = lib.lists.forEach identityFiles (file: "${config.home.homeDirectory}/.ssh/${file}");
      };

      "git" = {
        host = "gitlab.com github.com";
        user = "git";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = [ "~/.ssh/id_github" ];
      };

      #FIXME: Remove these hosts

      "beru" = lib.hm.dag.entryAfter [ "yubikey-hosts" ] {
        host = "beru";
        hostname = "192.168.1.20";
        user = "erwin";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = lib.lists.forEach identityFiles (file: "${config.home.homeDirectory}/.ssh/${file}");
      };

      "igris" = lib.hm.dag.entryAfter [ "yubikey-hosts" ] {
        host = "igris";
        hostname = "192.168.1.21";
        user = "erwin";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = lib.lists.forEach identityFiles (file: "${config.home.homeDirectory}/.ssh/${file}");
      };

      "bellial" = lib.hm.dag.entryAfter [ "yubikey-hosts" ] {
        host = "bellial";
        hostname = "192.168.1.22";
        user = "erwin";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = lib.lists.forEach identityFiles (file: "${config.home.homeDirectory}/.ssh/${file}");
      };

      # "oops" = lib.hm.dag.entryAfter [ "yubikey-hosts" ] {
      #   host = "oops";
      #   hostname = "${configVars.networking.subnets.oops.ip}";
      #   user = "${configVars.username}";
      #   port = configVars.networking.subnets.oops.port;
      #   forwardAgent = true;
      #   identitiesOnly = true;
      #   identityFile = [
      #     "~/.ssh/id_yubikey"
      #     "~/.ssh/id_borg"
      #   ];
      # };
      # "cakes" = {
      #   host = "${configVars.networking.external.cakes.name}";
      #   hostname = "${configVars.networking.external.cakes.ip}";
      #   user = "${configVars.networking.external.cakes.username}";
      #   localForwards = [
      #     {
      #       bind.address = "localhost";
      #       bind.port = configVars.networking.external.cakes.localForwardsPort;
      #       host.address = "localhost";
      #       host.port = configVars.networking.external.cakes.localForwardsPort;
      #     }
      #   ];
      # };
    } // vanillaHostsConfig;

  };
  home.file = {
    ".ssh/config.d/.keep".text = "# Managed by Home Manager";
    ".ssh/sockets/.keep".text = "# Managed by Home Manager";
  } // yubikeyPublicKeyEntries;
}
