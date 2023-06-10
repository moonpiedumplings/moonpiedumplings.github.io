let
    pkgs = import <nixpkgs> {};
    quarto = pkgs.callPackage ./env/quarto.nix {};
in
    pkgs.mkShell {
        packages = with pkgs; [ python310Full quarto jupyter ];
    }
