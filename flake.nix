{
  description = "An example of building a PureScript monorepo with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.11";
    easy-purescript-nix = {
      url = "github:f-f/easy-purescript-nix";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, easy-purescript-nix, }:
    let
      utils = import ./nix/utils.nix;

      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      overlay = final: prev: {
        pursPackages = prev.callPackage easy-purescript-nix { };
        nodejs = prev.nodejs-18_x-slim;
      };
    in utils.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in {
        devShells = {
          default = pkgs.mkShell {
            name = "shell";
            buildInputs = [ pkgs.pursPackages.spago ];
          };
        };

        formatter = pkgs.nixfmt;
      });
}
