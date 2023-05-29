{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    easy-purescript-nix.url = "github:f-f/easy-purescript-nix";
    easy-purescript-nix.flake = false;
    spago-nix.url = "github:thomashoneyman/spago-nix";
  };

  outputs = inputs: let
    utils.supportedSystems = ["x86_64-linux" "x86_64-darwin"];
    utils.eachSupportedSystem = inputs.utils.lib.eachSystem utils.supportedSystems;

    mkPackages = pkgs: let
      npmDependencies = pkgs.spago-npm-dependencies {src = ./.;};
      workspaces = pkgs.spago-lock {src = ./.;};
    in {
      # Build the PureScript package and bundle to a Node script.
      default = pkgs.stdenv.mkDerivation {
        name = "my-app";
        src = ./my-app;
        phases = ["buildPhase" "installPhase"];
        nativeBuildInputs = [pkgs.purescript pkgs.esbuild];
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

    mkDevShells = pkgs: pursPkgs: {
      default = pkgs.mkShell {
        buildInputs = [pursPkgs.purs pursPkgs.spago-next pkgs.esbuild];
      };
    };

    mkOutput = system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [inputs.spago-nix.overlay];
      };
      pursPkgs = pkgs.callPackage inputs.easy-purescript-nix {};
    in rec {
      packages = mkPackages pkgs;
      apps = mkApps pkgs packages;
      devShells = mkDevShells pkgs pursPkgs;
    };

    systemOutputs = utils.eachSupportedSystem mkOutput;
  in
    systemOutputs;
}
