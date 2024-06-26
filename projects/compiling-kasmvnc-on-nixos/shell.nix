let
  pkgs = import <nixpkgs> { };
  kasmvnc = pkgs.callPackage ./kasmvnctest.nix { };
in
pkgs.mkShell {
  packages = [ kasmvnc ];
}
