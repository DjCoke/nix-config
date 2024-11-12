{
  description = "EmergentMind's Nix-Config";

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      #
      # ========= Architectures =========
      #
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      configLib = import ./lib { inherit lib; };

      #
      # ========= Host Config Functions =========
      #
      # Handle a given host config based on whether it is for linux or darwin
      mkHost = host: isDarwin: {
        ${host} =
          let
            func = if isDarwin then nix-darwin.lib.darwinSystem else lib.nixosSystem;
            systemFunc = lib.trace isDarwin func;
            isDarwinFlag = isDarwin;
          in
          systemFunc {
            specialArgs = {
              inherit
                inputs
                outputs
                configLib
                isDarwinFlag
                ;
              lib = nixpkgs.lib // {
                custom = import ./lib { inherit (nixpkgs) lib; };
              };
            };
            modules = [ ./hosts/${if isDarwin then "darwin" else "linux"}/${host} ];
          };
      };
      # Invoke mkHost for each host config that is declared for either linux or darwin
      mkHostConfigs =
        hosts: isDarwin: lib.foldl (acc: set: acc // set) { } (lib.map (host: mkHost host isDarwin) hosts);
      # Return the hosts declared in the given directory
      readHosts = folder: lib.attrNames (builtins.readDir ./hosts/${folder});
    in
    {
      #
      # ========= Overlays =========
      #
      # Custom modifications/overrides to upstream packages.
      overlays = import ./overlays { inherit inputs outputs; };

      #
      # ========= Host Configurations =========
      #
      # Building configurations is available through `just rebuild` or `nixos-rebuild --flake .#hostname`
      nixosConfigurations = mkHostConfigs (readHosts "linux") false;
      #darwinConfigurations = mkHostConfigs (readHosts "darwin") true;

      #
      # ========= Custom Packages =========
      #
      # Custom pkgs to be shared or upstreamed.
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./pkgs { inherit pkgs; }
      );

      #
      # ========= Formatting =========
      #
      # Pre-commit checks
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./checks { inherit inputs system pkgs; }
      );
      # Nix formatter available through 'nix fmt' https://nix-community.github.io/nixpkgs-fmt
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      #
      # ========= DevShell =========
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

    };

  inputs = {
    #
    # ========= Official NixOS, Darwin, and HM Package Sources =========
    #
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

    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    #
    # ========= Utilities =========
    #
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
    # Pre-commit
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Theming
    stylix.url = "github:danth/stylix/release-24.05";
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";

    #
    # ========= Personal Repositories =========
    #
    # Private secrets repo.  See ./docs/secretsmgmt.md
    # Authenticate via ssh and use shallow clone
    nix-secrets = {
      url = "git+ssh://git@gitlab.com/emergentmind/nix-secrets.git?ref=main&shallow=1";
      inputs = { };
    };
  };
}
