{
  inputs = {
    nixpkgs.url = "nixpkgs";
  };
  outputs = inputs @ {nixpkgs, ...}: let

    #pkgs = import nixpkgs {};

    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

  in {

    devShells = forAllSystems (pkgs: {
      default = import ./shell.nix { inherit nixpkgs; };
    });
  };
}
