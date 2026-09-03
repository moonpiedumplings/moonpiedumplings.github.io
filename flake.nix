{
  nixConfig = {
    # IOG cache to prevent rebuilding GHC when getting newer pandoc
    extra-substituters = [ "https://cache.iog.io" ];
    extra-trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
    allow-import-from-derivation = "true";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
    pandoc-flake.url = "github:moonpiedumplings/pandoc-flake/c60895a198d85bd936e7cd117afc876605b873f3";
  };
  outputs =
    inputs@{ nixpkgs
    , ...
    }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            # "i686-linux" "aarch64-darwin" "x86_64-darwin"
          ]
          (
            system:
            function (
              import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              }
            )
          );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = import ./devshell.nix { inherit pkgs inputs; };
      });
      packages = forAllSystems (pkgs: {
        default = pkgs.buildEnv {
          name = "dev-shell";
          postBuild = ''
            export SHELL='/bin/bash'
          '';
        };
      });

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}
