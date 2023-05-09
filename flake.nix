{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  outputs = { self, nixpkgs }:
    let
      utils = import ./nix/utils.nix;
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

    in utils.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Use the spago.lock file to fetch all the project dependencies
        # from the PureScript registry.
        dependencies = (pkgs.callPackage ./nix/fetch-packages.nix { }) {
          lockfile = ./spago.lock;
        };

        # Build the PureScript package and bundle to a Node script.
        package = pkgs.stdenv.mkDerivation {
          name = "my-package";
          phases = [ "buildPhase" "installPhase" ];
          nativeBuildInputs = [ pkgs.purescript pkgs.esbuild ];
          buildPhase = ''
            set -f
            purs compile ${dependencies.globs} ${./src}/**/*.purs
            set +f
            esbuild ./output/Main/index.js --bundle --outfile=app.js --platform=node --minify
          '';
          installPhase = ''
            mkdir $out
            cp app.js $out
          '';
        };

      in {
        # The basic package is the derivation for our bundle
        defaultPackage = package;

        # But we can turn it into an app (which we can then use in NixOS deploys)
        # by calling Node:
        defaultApp = {
          type = "app";
          program = "${
              pkgs.writeShellScriptBin "app" ''
                ${pkgs.nodejs}/bin/node -e 'require("${package}/app.js").main()'
              ''
            }/bin/app";
        };
      });
}

