{ pkgs ? import <nixpkgs> {} } :
    pkgs.mkShell {
        packages = with pkgs; [ python310Full quarto jupyter pandoc deno ];
    }
