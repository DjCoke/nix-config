{
  description = "Minimal NixOS configuration for bootstrapping systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko"; # Declarative partitioning and formatting
    #HACK: this is just here temporarily to get around checks
    home-manager = {
      #url = "github:nix-community/home-manager/release-24.05";
      #inputs.nixpkgs.follows = "nixpkgs-stable";
      url = "github:nix-community/home-manager";
      #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      configLib = import ../lib { inherit lib; };

      minimalSpecialArgs = {
        inherit inputs outputs configLib;
      };

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
            (configLib.relativeToRoot "hosts/common/optional/minimal.nix")
            (configLib.relativeToRoot "hosts/linux/${name}/hardware-configuration.nix")

            { networking.hostName = name; }
          ];
        });
    in
    {
      nixosConfigurations = {
        # host = newConfig "name" disk" "withSwap" "swapSize"
        # Swap size is in GiB
        grief = newConfig "grief" "/dev/vda" false "0";
        guppy = newConfig "guppy" "/dev/vda" false "0";
        gusto = newConfig "gusto" "/dev/sda" true "8";

        ghost = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = minimalSpecialArgs;
          modules = [
            inputs.disko.nixosModules.disko
            (configLib.relativeToRoot "hosts/common/disks/ghost.nix")
            ./minimal-configuration.nix
            { networking.hostName = "ghost"; }
            (configLib.relativeToRoot "hosts/linux/ghost/hardware-configuration.nix")
          ];
        };

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
