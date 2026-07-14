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
              inherit (pkgs) callPackage;
              inherit (import ./mkgodot.nix) mkGodot mkGodotNixosPatch;

              settings = builtins.fromJSON (builtins.readFile ./project.config.json) // {
                godot = self'.packages.godot;
                export-templates = self'.packages.export-templates;
                src = ./.;
              };
            in
            {
              godot = pkgs.godot;
              export-templates = pkgs.godot.export-templates-bin;

              linux = callPackage mkGodot {
                inherit (settings)
                  pname
                  version
                  src
                  godot
                  export-templates
                  ;
                preset = "linux";
              };

              windows = callPackage mkGodot {
                inherit (settings)
                  pname
                  version
                  src
                  godot
                  export-templates
                  ;
                preset = "windows";
              };

              web = callPackage mkGodot {
                inherit (settings)
                  pname
                  version
                  src
                  godot
                  export-templates
                  ;
                preset = "web";
              };

              nixos = callPackage mkGodotNixosPatch {
                inherit (settings) version;
                pname = "${settings.pname}-nixos";
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
