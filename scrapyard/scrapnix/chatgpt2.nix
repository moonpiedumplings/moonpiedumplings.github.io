{ haskellPackages ? import (fetchTarball "https://github.com/input-output-hk/haskell.nix/archive/master.tar.gz") {} }:

let
  pkgs = haskellPackages;
in
(import <nixpkgs> {}).mkShell {
  buildInputs = [
    pkgs.pandoc-cli
  ];
}
