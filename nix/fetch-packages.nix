{
  stdenv,
  callPackage,
  lib,
  fetchurl,
  fetchgit,
}: let
  # Import YAML parser
  fromYAML = callPackage ./from-yaml.nix {};

  # Read the YAML lock file
  lock = fromYAML (builtins.readFile ../spago.lock);

  fetchPackage = name: attr:
    if attr.type == "registry"
    then fetchRegistryPackage name attr
    else if attr.type == "git"
    then fetchGitPackage name attr
    else if attr.type == "github"
    then fetchGitHubPackage name attr
    else if attr.type == "local"
    then fetchWorkspacePackage name attr
    else throw "Unknown package type ${attr.type}";

  # Option 1: Fetch and unpack the given package from the registry
  # "effect": {
  #   "type": "registry",
  #   "version": "4.0.0",
  #   "integrity": "sha256-eBtZu+HZcMa5HilvI6kaDyVX3ji8p0W9MGKy2K4T6+M="
  # },
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

  # Option 2: Fetch the given package from a Git url. Requires a commit hash.
  # "console": {
  #   "type": "git",
  #   "url": "https://github.com/purescript/purescript-console.git",
  #   "rev": "3b83d7b792d03872afeea5e62b4f686ab0f09842"
  # },
  fetchGitPackage = name: attr: let
    fetched = builtins.fetchGit {
      inherit (attr) url rev;
      # Look at commit hashes across the repository, not just the default branch,
      # in case they are pointing to a non-default-branch commit.
      allRefs = true;
    };
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

  # Option 3: Fetch the given package from a GitHub tag
  # "numbers": {
  #   "type": "github",
  #   "owner": "purescript",
  #   "repo": "purescript-numbers",
  #   "tag": "v9.0.0",
  #   "integrity": "sha256-sv7H9ihP0Y5UnwlHuLVXEU736nUXZC5C5a0kKReFLBA="
  # },
  fetchGitHubPackage = name: attr: let
    fetched = fetchurl {
      name = "${attr.owner}-${attr.repo}-${attr.tag}.tar.gz";
      hash = attr.integrity;
      url = "https://github.com/${attr.owner}/${attr.repo}/archive/refs/tags/${attr.tag}.tar.gz";
    };
  in
    stdenv.mkDerivation {
      name = name;
      version = attr.tag;
      src =
        if builtins.hasAttr "subdir" attr
        then "${fetched}/${attr.subdir}"
        else fetched;
      installPhase = ''
        cp -R . "$out"
      '';
    };

  # Option 4: Fetch the given package from the local workspace
  # "my-library": {
  #   "type": "workspace",
  #   "path": "my-library"
  # },
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
