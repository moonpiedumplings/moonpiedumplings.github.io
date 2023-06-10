{ pkgs ? import (fetchTarball {
		url = "https://github.com/seam345/nixpkgs/archive/89e6e477c8357a087e863db562d2fa8d9fe5ba29.tar.gz";
		sha256 = "1jjkfzjls2b363lxad8xigqigfkzwyvdrr4d3m84vbs9s4xa7hp2";
	}) {} } :
let
	pandoc = pkgs.haskellPackages.pandoc-cli;
	quarto = (pkgs.quarto.overrideAttrs (oldAttrs: rec {
        version = "1.3.361";
        src = pkgs.fetchurl {
            url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
            sha256 = "sha256-vvnrIUhjsBXkJJ6VFsotRxkuccYOGQstIlSNWIY5nuE=";
        };
    })).override {inherit pandoc;};
in
	pkgs.mkShell {
		packages = [ quarto ];
	}
