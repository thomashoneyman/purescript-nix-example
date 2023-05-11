{
  stdenv,
  callPackage,
  lib,
  fetchurl,
  fetchgit,
}: let
  # Read the JSON lock file
  lock = builtins.fromJSON (builtins.readFile ../spago.lock);

  fetchPackage = name: attr:
    if attr.type == "registry"
    then fetchRegistryPackage name attr
    else if attr.type == "git"
    then fetchGitPackage name attr
    else if attr.type == "workspace"
    then fetchWorkspacePackage name attr
    else throw "Unknown package type ${attr.type}";

  # Option 1: Fetch and unpack the given package from the registry
  fetchRegistryPackage = name: attr:
    stdenv.mkDerivation {
      name = name;
      version = attr.version;

      src = fetchurl {
        name = "${name}-${attr.version}.tar.gz";
        hash = attr.integrity;
        url = "https://packages.registry.purescript.org/${name}/${attr.version}.tar.gz";
      };

      installPhase = ''
        cp -R . "$out"
      '';
    };

  # Option 2: Fetch the given package from a Git url
  fetchGitPackage = name: attr: let
    fetched = builtins.fetchGit {inherit (attr) url rev;};
  in
    stdenv.mkDerivation {
      name = name;
      src =
        if builtins.hasAttr "subdir" attr
        then "${fetched}/${attr.subdir}"
        else fetched;
      installPhase = ''
        cp -R . "$out"
      '';
    };

  # Option 3: Fetch the given package from the local workspace
  fetchWorkspacePackage = name: attr:
    stdenv.mkDerivation {
      name = name;
      src = "${../.}/${attr.path}";
      installPhase = ''
        cp -R . "$out"
      '';
    };

  # Fetch all the packages
  fetchedPackages = lib.mapAttrs fetchPackage lock.packages;

  # Convert the set of derivations into a space-separated string of Nix store paths
  storePaths = builtins.attrValues fetchedPackages;

  # Turn them into glob patterns acceptable for the compiler
  storeGlobs =
    builtins.concatStringsSep " "
    (builtins.map (path: "'${path}/src/**/*.purs'") storePaths);
in {
  packages = fetchedPackages;
  paths = storePaths;
  globs = storeGlobs;
}
