{
  description = "LLM Sandbox Tooling";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell.url = "github:numtide/devshell";
  };

  outputs = { self, devshell, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication mkPoetryEnv;
        inherit (pkgs) writeShellApplication;
      in
      {
        packages = {
          # this package is the base poetry package/environment that will be reused in this flake
          llm-sandbox = mkPoetryEnv
            {
              projectDir = self;
              preferWheels = true;
              editablePackageSources = {
                llm-sandbox = self;
              };
            };
          jupyter-server = writeShellApplication {
            name = "jupyter-server";
            text = ''
              exec "${self.packages.${system}.llm-sandbox}/bin/jupyter" "notebook" "$@"
            '';
          };
        };

        apps = {
          jupyter = {
            type = "app";
            program = "${self.packages.${system}.llm-sandbox}/bin/jupyter";
          };
          jupyter-server = {
            type = "app";
            program = "${self.packages.${system}.jupyter-server}/bin/jupyter-server";
          };
        };

        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

        devShells.devshell =
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ devshell.overlays.default ];
            };
          in
          pkgs.devshell.mkShell {
            name = "llm-sandbox-devshell";
            packages = [
              #              self.packages.${system}.llm-sandbox
              pkgs.poetry.python
              pkgs.poetry
              pkgs.pre-commit
            ];

            commands = [{
              name = "jupyter";
              command = ''${pkgs.poetry}/bin/poetry run jupyter "$@"'';
            }];
            env = [ ];
          };
        devShells.default = self.devShells.${system}.devshell;
      });
}
