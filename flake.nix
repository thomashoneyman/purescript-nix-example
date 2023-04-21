{
  description = "An example of building a PureScript monorepo with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.11";
    purifix.url = "github:purifix/purifix";
    easy-purescript-nix = {
      url = "github:f-f/easy-purescript-nix";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, easy-purescript-nix, purifix }:
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
          overlays = [ overlay purifix.overlay ];
        };

        my-package = pkgs.purifix { src = ./.; };
      in {
        packages = { default = my-package; };

        defaultPackage = my-package;

        devShells = {
          default = pkgs.mkShell {
            name = "shell";
            buildInputs =
              [ pkgs.pursPackages.spago-next pkgs.pursPackages.purs ];
          };
        };

        formatter = pkgs.nixfmt;
      });
}
