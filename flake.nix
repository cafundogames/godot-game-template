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
              inherit (import ./mkgodot.nix) mkGodotGame patchGodotGame;
              inherit (builtins) fromJSON readFile;
              settings = fromJSON (readFile ./project.config.json);
              mkGodotGamePackage =
                preset: src:
                callPackage mkGodotGame {
                  inherit (settings) pname version;
                  inherit preset src;
                };
            in
            {
              linux = mkGodotGamePackage "linux" ./.;
              windows = mkGodotGamePackage "windows" ./.;
              web = mkGodotGamePackage "web" ./.;

              nixos = callPackage patchGodotGame {
                inherit (settings) pname version;
                src = self'.packages.linux;
              };
            };
          devshells.default = {
            packages = [ pkgs.godot ];
            devshell.motd = "\\";
          };
        };
    };
}
