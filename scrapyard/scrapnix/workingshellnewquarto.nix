{ pkgs ? import (fetchTarball {
        url = "https://github.com/moonpiedumplings/nixpkgs/archive/53d78509bc67d9df0dcbc74f77c5ea759f082502.tar.gz";
        sha256 = "1ikfs00azdn2ws84b6kdnirpi26qv7y1bz98l1nkn0b0lr03ida8";}) {} } :
    pkgs.mkShell {
        packages = with pkgs; [ python310Full quarto jupyter deno ];
    }
