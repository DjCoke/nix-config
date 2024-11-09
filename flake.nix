{
  description = "EmergentMind's Nix-Config";

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        #"aarch64-darwin"
      ];
      configVars = import ./vars { inherit inputs lib; };
      configLib = import ./lib { inherit lib; };

      specialArgs = {
        inherit
          inputs
          outputs
          configVars
          configLib
          nixpkgs
          ;
      };
    in
    {
      # Custom modifications/overrides to upstream packages.
      overlays = import ./overlays { inherit inputs outputs; };

      # Custom packages to be shared or upstreamed.
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./pkgs { inherit pkgs; }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./checks { inherit inputs system pkgs; }
      );

      # Nix formatter available through 'nix fmt' https://nix-community.github.io/nixpkgs-fmt
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # ################### DevShell ####################
      #
      # Custom shell for bootstrapping on new hosts, modifying nix-config, and secrets management

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          checks = self.checks.${system};
        in
        import ./shell.nix { inherit checks pkgs; }
      );

      #################### NixOS Configurations ####################
      #
      # Building configurations available through `just rebuild` or `nixos-rebuild --flake .#hostname`

      nixosConfigurations = {
        # Main
        ghost = lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ./hosts/ghost
          ];
        };
        # Qemu VM dev lab
        grief = lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ./hosts/grief
          ];
        };
        # Qemu VM deployment test lab
        guppy = lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ./hosts/guppy
          ];
        };
        # Theatre - ASUS VivoPC VM40B-S081M
        gusto = lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ./hosts/gusto
          ];
        };
      };
    };

  inputs = {
    #################### Official NixOS and HM Package Sources ####################

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # The next two are for pinning to stable vs unstable regardless of what the above is set to
    # See also 'stable-packages' and 'unstable-packages' overlays at 'overlays/default.nix"
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      #url = "github:nix-community/home-manager/release-24.05";
      #inputs.nixpkgs.follows = "nixpkgs-stable";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    #################### Utilities ####################

    # Declarative partitioning and formatting
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management. See ./docs/secretsmgmt.md
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vim4LMFQR!
    nixvim = {
      #url = "github:nix-community/nixvim/nixos-24.05";
      #inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming
    stylix.url = "github:danth/stylix/release-24.05";
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";

    #################### Personal Repositories ####################

    # Private secrets repo.  See ./docs/secretsmgmt.md
    # Authenticate via ssh and use shallow clone
    nix-secrets = {
      url = "git+ssh://git@gitlab.com/emergentmind/nix-secrets.git?ref=main&shallow=1";
      inputs = { };
    };
  };
}
