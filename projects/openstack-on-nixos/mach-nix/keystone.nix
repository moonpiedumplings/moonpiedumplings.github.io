{
    nixpkgs ? import <nipxkgs>,
    #fetchFromGithub,
    fetchgit,
    python3
} : 

let
    mach-nix = import (fetchgit {
    url = "https://github.com/DavHau/mach-nix";
    rev = "65266b5cc867fec2cb6a25409dd7cd12251f6107";
    sha256 = "sha256-1OBBlBzZ894or8eHZjyADOMnGH89pPUKYGVVS5rwW/0=";
    }) {};
in

mach-nix.buildPythonApplication {
    pname =  "keystone";
    version = "placeholder";
    src = fetchgit {
        url = "https://github.com/openstack/keystone/";
        rev = "040e6d09b1e7e6817c81209c2b089d318715bef6";
    };
}