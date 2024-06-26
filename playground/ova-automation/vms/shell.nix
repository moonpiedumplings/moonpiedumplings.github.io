# { pkgs ? import <nixpkgs> { } }:
{ pkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz) { } }:

let
  my-python-packages = ps: with ps; [
    ansible
    ansible-core
    molecule
    molecule-plugins
    dnspython
    jmespath
    pywinrm
    sqlalchemy
    mysqlclient
    psycopg2
    requests
    pyopenssl
    pymongo
    # other python packages
  ];
  #vagrantPackage = if builtins.pathExists /etc/wsl.conf then "" else "vagrant";
  vagrantDefaultProvider = if builtins.pathExists /etc/wsl.conf then "virtualbox" else "libvirt";
in
with pkgs;
mkShell {
  LC_ALL = "C.UTF-8";
  LANG = "C.UTF-8";
  ANSIBLE_HOST_KEY_CHECKING = "False";
  VAGRANT_WSL_ENABLE_WINDOWS_ACCESS = "1";
  VAGRANT_DEFAULT_PROVIDER = "${vagrantDefaultProvider}";
  buildInputs = [
    podman
    podman-compose
    #zellij
    vagrant
    openssh
    sshpass
    sshs
    (pkgs.python311.withPackages my-python-packages)
    ansible-lint
  ];
}
