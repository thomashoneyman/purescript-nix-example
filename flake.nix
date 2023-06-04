{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    purescript-nix.url = "github:thomashoneyman/purescript-nix";
    purescript-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: let
    utils.supportedSystems = ["x86_64-linux" "x86_64-darwin"];
    utils.eachSupportedSystem = inputs.utils.lib.eachSystem utils.supportedSystems;

    mkPackages = pkgs: let
      npmDependencies = pkgs.buildPackageLock {src = ./.;};
      workspaces = pkgs.buildSpagoLock {src = ./.;};
    in {
      # Build the PureScript package and bundle to a Node script.
      default = pkgs.stdenv.mkDerivation {
        name = "my-app";
        src = ./my-app;
        phases = ["buildPhase" "installPhase"];
        nativeBuildInputs = [pkgs.purs.purs-unstable pkgs.esbuild];
        buildPhase = ''
          ln -s ${npmDependencies}/js/node_modules .
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
    };

    mkApps = pkgs: packages: {
      default = {
        type = "app";
        program = "${
          pkgs.writeShellScriptBin "run-package" ''
            ${pkgs.nodejs}/bin/node -e 'require("${packages.default}/app.js").main()'
          ''
        }/bin/run-package";
      };
    };

    mkDevShells = pkgs: {
      default = pkgs.mkShell {
        buildInputs = [pkgs.purs.purs-unstable pkgs.spago.spago pkgs.esbuild];
      };
    };

    mkOutput = system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [inputs.purescript-nix.overlays.default];
      };
    in rec {
      packages = mkPackages pkgs;
      apps = mkApps pkgs packages;
      devShells = mkDevShells pkgs;
    };

    systemOutputs = utils.eachSupportedSystem mkOutput;
  in
    systemOutputs;
}
