{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  inputs.easy-purescript-nix = {
    url = "github:f-f/easy-purescript-nix";
    flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    easy-purescript-nix,
  }: let
    utils = import ./nix/utils.nix;
    supportedSystems = ["x86_64-linux" "x86_64-darwin"];
  in
    utils.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {inherit system;};

      pursPkgs = pkgs.callPackage easy-purescript-nix {};

      # This function will fetch packages from the registry, given a lockfile.
      spagoLock = pkgs.callPackage ./nix/spago-lock.nix {};

      # When used, we get the available workspaces
      workspaces = spagoLock {src = ./.;};

      # Build the PureScript package and bundle to a Node script.
      package = pkgs.stdenv.mkDerivation {
        name = "my-app";
        src = ./my-app;
        phases = ["buildPhase" "installPhase"];
        nativeBuildInputs = [pkgs.purescript pkgs.esbuild];
        buildPhase = ''
          set -f
          purs compile $src/**/*.purs ${workspaces.my-app.dependencies.globs}
          set +f
          esbuild ./output/App.Main/index.js --bundle --outfile=app.js --platform=node --minify
        '';
        installPhase = ''
          mkdir $out
          cp app.js $out
        '';
      };

      # A wrapper script to run the application with Node
      run-package = pkgs.writeShellScriptBin "run-package" ''
        ${pkgs.nodejs}/bin/node -e 'require("${package}/app.js").main()'
      '';
    in {
      # Development shell
      devShells.default = pkgs.mkShell {
        buildInputs = [pkgs.purescript pursPkgs.spago-next pkgs.esbuild];
      };

      # The basic package is the derivation for our bundle.
      packages.default = package;

      # The runnable app (for deployments) calls out to Node.
      apps.default = {
        type = "app";
        program = "${run-package}/bin/run-package";
      };
    });
}
