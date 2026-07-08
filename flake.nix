{
  description = "Godot development environment";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devshell.flakeModule ];
      systems = [ "x86_64-linux" ];
      perSystem =
        { self', pkgs, ... }:
        {
          packages =
            let
              mkGodot = pkgs.callPackage (import ./mkgodot.nix).mkGodot {
                godot = self'.packages.godot;
                export-templates = self'.packages.export-templates;
              };
              mkGodotNixosPatch = pkgs.callPackage (import ./mkgodot.nix).mkGodotNixosPatch { };
              settings = builtins.fromJSON (builtins.readFile ./project.config.json);
              src = ./.;
            in
            {
              godot = pkgs.godot;
              export-templates = pkgs.godot.export-templates-bin;

              linux = mkGodot {
                inherit (settings) pname version;
                inherit src;
                preset = "linux";
              };

              windows = mkGodot {
                inherit (settings) pname version;
                inherit src;
                preset = "windows";
              };

              web = mkGodot {
                inherit (settings) pname version;
                inherit src;
                preset = "web";
              };

              nixos = mkGodotNixosPatch {
                inherit (settings) pname version;
                src = self'.packages.linux;
              };
            };
          devshells.default = {
            packages = [ self'.packages.godot ];
            commands = [
              {
                name = "edit";
                command = "godot -e";
              }
              {
                name = "run";
                command = "godot --path ./.";
              }
            ];
            devshell.motd = "\\";
          };
        };
    };
}
