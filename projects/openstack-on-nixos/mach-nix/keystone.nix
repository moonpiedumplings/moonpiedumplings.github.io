{
    pkgs ? import <nipxkgs> {}, 
    #pkgs ? (import fetchtarball {"https://github.com/nixos/nixpkgs/archive/f10cdcf31dd2a436edbf7f0ad82c44b911804bc8.tar.gz"}),
    fetchgit,
    versionPy ? "39"
} : 

let
    python = pkgs."python${versionPy}Full";
    pythonPackages = pkgs."python${versionPy}Packages";
    mach-nix = import (fetchGit {
    url = "https://github.com/DavHau/mach-nix";
    rev = "65266b5cc867fec2cb6a25409dd7cd12251f6107";
    #sha256 = "sha256-1OBBlBzZ894or8eHZjyADOMnGH89pPUKYGVVS5rwW/0=";
    }) {inherit pkgs python pythonPackages;};
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
    pypiDataRev = "e9571cac25d2f509e44fec9dc94a3703a40126ff";
    pypiDataSha256 = "1rbb0yx5kjn0j6lk0ml163227swji8abvq0krynqyi759ixirxd5";
}