{ nixpkgs ? import <nixpkgs> {}
, haskellPackages ? import nixpkgs {
    overlays = [ (import (builtins.fetchTarball "https://github.com/input-output-hk/haskell.nix/archive/master.tar.gz")) ];
  }
}:

let
  # Import Haskell packages using haskell.nix
  pkgs = haskellPackages;
in
pkgs.mkShell {
  buildInputs = [
    pkgs.ghc
    pkgs.cabal-install
    # Add any additional Haskell packages you need here
    pkgs.aeson
    pkgs.text
    pkgs.pandoc
  ];
}
