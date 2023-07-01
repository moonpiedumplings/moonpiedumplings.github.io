{
    pkgs ? import <nipxkgs> {}, 
    #pkgs ? (import fetchtarball {"https://github.com/nixos/nixpkgs/archive/f10cdcf31dd2a436edbf7f0ad82c44b911804bc8.tar.gz"}),
    #poetry2nix ? (import fetchtarball {"https://github.com/nix-community/poetry2nix/archive/215afa14f7077ca0610882d6d18ac3454f48fa65.tar.gz"}),
    fetchgit,
} : 

let
    /*poetryConverter = src: pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
    ${pkgs.poetry}/bin/poetry self add poetry-plugin-import
    mkdir $out
    ln -s ${pkg}/* $out
    rm $out/bin
    mkdir $out/bin
  '';*/
    poetry2nix = import (builtins.fetchTarball {
    url = "https://github.com/nix-community/poetry2nix/archive/215afa14f7077ca0610882d6d18ac3454f48fa65.tar.gz";
    sha256 = "0k0blf48ln6bcj7c76cjjcdx41l1ygscpczi2k2d2vqv14a5bzan";
  }) {};
in
poetry2nix.mkPoetryApplication {
    src = fetchgit {
        url = "https://github.com/openstack/keystone/";
        rev = "040e6d09b1e7e6817c81209c2b089d318715bef6";
        sha256 = "sha256-qQgGh0WwEDSYQC1PDnSDp3RUiWoFjV5SCjw0SiUlJtk=";
    };
}