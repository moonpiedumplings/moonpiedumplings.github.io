let
	pkgs = import (fetchTarball {
		url = "https://github.com/nixos/nixpkgs/archive/138d6b446388e85f3f7d8c0d6661a46519aa3530.tar.gz";
		sha256 = "17adlrdnlk25ihwixjm6x442f73ky89827nw3wzvlvc9h2chs3yq";
	}) {};
in
	pkgs.mkShell {
		packages = with pkgs; [ haskellPackages.pandoc_3_1_2 ];
	}
