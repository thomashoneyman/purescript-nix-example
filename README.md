# Nix Example

A small example project that demonstrates building a PureScript project with Spago and Nix. The PureScript project is a monorepo where `my-app` is the main application and `my-library` contains extra shared code the package relies on.

We fully leverage Nix such that there is a simple Nix command for building, testing, and running the application.

- `nix build` -> bundle the project
- `nix run` -> execute `Main`

In the future this small example may demonstrate a monorepo setup, deployment via a Nix ops tool to a local VM or a cloud provider, integration with JavaScript dependencies, and integration tests.
