let
    pkgs = import <nixpkgs> {};
    quarto = pkgs.callPackage ./env/quarto.nix {};
in
    pkgs.mkShell {
        packages = with pkgs; [ python310Full quarto jupyter texlive.combined.scheme-full python310Packages.ipywidgets python310Packages.matplotlib python310Packages.bqplot];
    }
