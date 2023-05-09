{ stdenv, callPackage, lib, fetchurl }:

{ lockfile }:

let
  # Read the JSON lock file
  lock = builtins.fromJSON (builtins.readFile lockfile);

  # Fetch and unpack the given package from the registry
  fetchPackageTarball = name: attr:
    stdenv.mkDerivation {
      pname = name;
      version = attr.version;

      src = fetchurl {
        name = "${name}-${attr.version}.tar.gz";
        hash = attr.integrity;
        url =
          "https://packages.registry.purescript.org/${name}/${attr.version}.tar.gz";
      };

      installPhase = ''
        cp -R . "$out"
      '';
    };

  # Fetch all the packages
  fetchedPackages = lib.mapAttrs fetchPackageTarball lock.packages;

  # Convert the set of derivations into a space-separated string of Nix store paths
  storePaths = builtins.attrValues fetchedPackages;

  # Turn them into glob patterns acceptable for the compiler
  storeGlobs = builtins.concatStringsSep " "
    (builtins.map (path: "'${path}/src/**/*.purs'") storePaths);

in {
  packages = fetchedPackages;
  paths = storePaths;
  globs = storeGlobs;
}
