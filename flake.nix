{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }:
    let
      utils = import ./nix/utils.nix;
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

    in utils.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # This function will fetch packages from the registry, given a lockfile.
        fetchDependencies = pkgs.callPackage ./nix/fetch-packages.nix { };

        # Use the spago.lock file to fetch all the project dependencies.
        dependencies = fetchDependencies { lockfile = ./spago.lock; };

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

        # A wrapper script to run the application with Node
        application = pkgs.writeShellScriptBin "app" ''
          ${pkgs.nodejs}/bin/node -e 'require("${package}/app.js").main()'
        '';

      in {
        # The basic package is the derivation for our bundle.
        packages.default = package;

        # The runnable app (for deployments) calls out to Node.
        apps.default = {
          type = "app";
          program = "${application}/bin/app";
        };
      });
}
