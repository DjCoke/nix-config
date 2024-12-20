{
  description = "Minimal NixOS configuration for bootstrapping systems";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    # Declarative partitioning and formatting
    disko.url = "github:nix-community/disko";
    nix-secrets = {
      url = "git+ssh://git@github.com/DjCoke/nix-secrets.git?ref=main&shallow=1";
      inputs = { };
    };

  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      configVars = import ../vars { inherit inputs lib; };
      configLib = import ../lib { inherit lib; };
      minimalConfigVars = lib.recursiveUpdate configVars { isMinimal = true; };
      minimalSpecialArgs = {
        inherit inputs outputs configLib;
        configVars = minimalConfigVars;
      };

      # FIXME:(installer) Specify arch eventually probably
      # This mkHost is way better: https://github.com/linyinfeng/dotfiles/blob/8785bdb188504cfda3daae9c3f70a6935e35c4df/flake/hosts.nix#L358
      newConfig =
        name: disk: withSwap: swapSize:
        (nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = minimalSpecialArgs;
          modules = [
            inputs.disko.nixosModules.disko
            (configLib.relativeToRoot "hosts/common/disks/standard-disk-config.nix")
            {
              _module.args = {
                inherit disk withSwap swapSize;
              };
            }
            ./minimal-configuration.nix
            { networking.hostName = name; }
            (
              if builtins.match "k3s-[0-9][0-9]?" name != null then
                configLib.relativeToRoot "hosts/k3s/hardware-configuration.nix"
              else
                configLib.relativeToRoot "hosts/${name}/hardware-configuration.nix"
            )
          ];
        });
    in
    {
      nixosConfigurations = {
        # host = newConfig "name" disk" "withSwap" "swapSize"
        # Swap size is in GiB
        # grief = newConfig "grief" "/dev/vda" false "0";
        # guppy = newConfig "guppy" "/dev/vda" false "0";
        # gusto = newConfig "gusto" "/dev/sda" true "8";

        k3s-01 = newConfig "k3s" "/dev/sda" true "8";
        k3s-02 = newConfig "k3s" "/dev/sda" true "8";
        k3s-03 = newConfig "k3s" "/dev/sda" true "8";
        k3s-04 = newConfig "k3s" "/dev/sda" false "0";
        k3s-05 = newConfig "k3s" "/dev/sda" false "0";
        k3s-06 = newConfig "k3s" "/dev/sda" false "0";
        k3s-07 = newConfig "k3s" "/dev/sda" false "0";
        k3s-08 = newConfig "k3s" "/dev/sda" false "0";
        k3s-09 = newConfig "k3s" "/dev/sda" false "0";
        # ghost = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   specialArgs = minimalSpecialArgs;
        #   modules = [
        #     inputs.disko.nixosModules.disko
        #     (configLib.relativeToRoot "hosts/common/disks/ghost.nix")
        #     ./minimal-configuration.nix
        #     { networking.hostName = "ghost"; }
        #     (configLib.relativeToRoot "hosts/ghost/hardware-configuration.nix")
        #   ];
        # };

        # Custom ISO
        #
        # `just iso` - from nix-config directory to generate the iso standalone
        # 'just iso-install <drive>` - from nix-config directory to generate and copy directly to USB drive
        # `nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage` - from nix-config directory to generate the iso manually
        #
        # Generated images will be output to the ~/nix-config/results directory unless drive is specified
        iso = nixpkgs.lib.nixosSystem {
          specialArgs = minimalSpecialArgs;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            ./iso
          ];
        };
      };
    };
}
