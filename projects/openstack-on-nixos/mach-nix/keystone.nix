{
    pkgs ? import <nipxkgs>,
    #fetchFromGithub,
    fetchgit,
    versionPy ? "39"
} : 

let
    mach-nix = import (fetchgit {
    url = "https://github.com/DavHau/mach-nix";
    rev = "65266b5cc867fec2cb6a25409dd7cd12251f6107";
    sha256 = "sha256-1OBBlBzZ894or8eHZjyADOMnGH89pPUKYGVVS5rwW/0=";
    }) {};
    python = pkgs."python${versionPy}Full";
    pythonPkgs = pkgs."python${versionPy}Packages";
in

mach-nix.buildPythonApplication {
    python = pkgs."python${versionPy}Full";
    pythonPkgs = pkgs."python${versionPy}Packages";
    pname =  "keystone";
    version = "placeholder";
    src = fetchgit {
        url = "https://github.com/openstack/keystone/";
        rev = "040e6d09b1e7e6817c81209c2b089d318715bef6";
    };
}