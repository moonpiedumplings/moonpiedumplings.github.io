let
	pkgs = import (builtins.fetchGit {
    	url = "https://github.com/nixos/nixpkgs";
    	ref = "refs/heads/haskell-updates";
    	rev = "9d886b026546ede5ff40c6e09d2f6161c8fb1269";
  }) {};
in
	pkgs.mkShell {
		packages = with pkgs; [ quarto ];
	}
