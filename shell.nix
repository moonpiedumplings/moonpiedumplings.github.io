let
    pkgs = import <nixpkgs> {};
    quarto = pkgs.callPackage ./env/quarto.nix {};
    python3 = pkgs.python311;
    pythonDeps = ps: with ps; [ 
		jupyter notebook qtconsole jupyter_console 
		nbconvert 
		ipykernel ipywidgets matplotlib 
		#bqplot 
		pip ];
in
    pkgs.mkShell {
        QUARTO_PYTHON = "${pkgs.python3.withPackages pythonDeps}/bin/python3";
        packages = with pkgs; [ 
	    nodePackages_latest.npm
            (python3.withPackages pythonDeps)
            quarto
            texlive.combined.scheme-full
            ];
    }
