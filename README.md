# Nix Example

A small example project that demonstrates how to build a PureScript project with Spago and Nix via Purifix. The goal is to fully leverage Nix, in that there should be a simple Nix command for any common activity in the project:

- `nix build` -> bundle the project
- `nix run` -> execute `Main`
- `nix flake check` -> run the project tests

In the future this small example may demonstrate a monorepo setup, deployment via a Nix ops tool to a local VM or a cloud provider, integration with JavaScript dependencies, and integration tests.
