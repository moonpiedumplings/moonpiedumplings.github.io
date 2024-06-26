{ pkgs ? import <nipxkgs> { }
, #pkgs ? (import fetchtarball {"https://github.com/nixos/nixpkgs/archive/f10cdcf31dd2a436edbf7f0ad82c44b911804bc8.tar.gz"}),
  fetchgit
, fetchPypi
, #fetchFromGitHub,
  versionPy ? "39"
,
}:

let
  #python = pkgs."python${versionPy}Full";
  #pythonPackages = pkgs."python${versionPy}Packages";
  mach-nix = import
    (fetchgit {
      url = "https://github.com/DavHau/mach-nix";
      rev = "65266b5cc867fec2cb6a25409dd7cd12251f6107";
      sha256 = "sha256-1OBBlBzZ894or8eHZjyADOMnGH89pPUKYGVVS5rwW/0=";
    })
    {
      python = "python39";
      pythonPackages = "python39Packages";

      pypiDataRev = "e9571cac25d2f509e44fec9dc94a3703a40126ff";
      pypiDataSha256 = "1rbb0yx5kjn0j6lk0ml163227swji8abvq0krynqyi759ixirxd5";
    };
in

mach-nix.buildPythonPackage rec {
  pname = "keystone";
  version = "23.0.0";
  PBR_VERSION = "${version}";

  /*src = fetchgit {
        url = "https://github.com/openstack/keystone/";
        rev = "040e6d09b1e7e6817c81209c2b089d318715bef6";
        sha256 = "sha256-qQgGh0WwEDSYQC1PDnSDp3RUiWoFjV5SCjw0SiUlJtk=";
    };*/
  /*src = fetchTarball {
        url = "https://github.com/openstack/keystone/archive/eff960e124e2f28922067800547e23f1931d3c4a.tar.gz";
        sha256 = "";
    };*/
  src = builtins.fetchGit {
    url = "https://github.com/openstack/keystone/";
    ref = "refs/tags/23.0.0";
    rev = "c08d97672dcd40f8d927f91e59049053cfe3b5e4";
    #sha256 = "sha256-JYP29APY27BpX9GSyayW/y7rskdn8zW5mVsjdBXjCus=";
  };
  /*src = fetchPypi {
        inherit pname version;
        sha256 = "sha256-t0ravo9+H2nYcoGkvoxn5YxHOTf68vSon+VTJFn6INY=";
    };*/
  /*src = fetchFromGitHub {
        owner = "openstack";
        repo = "keystone";
        tag = "23.0.0";
   };*/
  /*src = fetchTarball {
        url = "https://github.com/openstack/keystone/archive/refs/tags/23.0.0.tar.gz";
        sha256 = "";
    };*/
  #src = /home/moonpie/vscode/keystone; # currently in correct tag

  requirements = builtins.readFile "${src}/requirements.txt";

}
