# Nix Example

A small example project that demonstrates building a PureScript project with Spago and Nix. The PureScript project is a monorepo where `my-app` is the main application and `my-library` contains extra shared code the package relies on.

We fully leverage Nix such that there is a simple Nix command for building, testing, and running the application.

- `nix build` -> bundle the project
- `nix run` -> execute `Main`

This is currently using a pseudo Spago lockfile that Nix can import from. The lockfile demonstrates a few ways a package can be specified, as also seen in the spago.yaml files:

```jsonc
// A registry package
{
  "type": "registry",
  "version": "1.0.0",
  "integrity": "sha256-abc"
}

// A remote git package
{
  "type": "git",
  "url": "https://github.com/pkg/my-pkg.git",
  "ref": "abc123",
  "subdir": "pkg",
  "integrity": "sha256-abc"
}

// A local package
{
  "type": "local",
  "path": "./my-package"
}
```

In the future this small example may demonstrate a monorepo setup, deployment via a Nix ops tool to a local VM or a cloud provider, integration with JavaScript dependencies, and integration tests.
