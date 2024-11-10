# Core functionality for every nix-darwin host

{ inputs, lib, ... }:
{
  imports = lib.flatten [
    #inputs.home-manager.darwinModules.home-manager
    #inputs.sops-nix.darwinModules.sops
    #inputs.stylix.darwinModules.stylix
    #inputs.nix-index-database.darwinModules.nix-index
    #inputs.nixvim-flake.darwinModules.nixvim
    (map lib.custom.relativeToRoot [ "modules/darwin" ])
    ./sops.nix
  ];
}
