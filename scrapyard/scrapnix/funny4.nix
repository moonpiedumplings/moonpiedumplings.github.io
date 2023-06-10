let
	pkgs = import (fetchTarball {
		url = "https://github.com/seam345/nixpkgs/archive/89e6e477c8357a087e863db562d2fa8d9fe5ba29.tar.gz";
		sha256 = "1jjkfzjls2b363lxad8xigqigfkzwyvdrr4d3m84vbs9s4xa7hp2";
	}) {};
in
	pkgs.mkShell {
		packages = with pkgs; [ haskellPackages.pandoc-cli quarto jupyter deno ];
	}
