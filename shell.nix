let
    pkgs = import <nixpkgs> {};

    python3 = pkgs.python311;
    pythonDeps = ps: with ps; [ 
		jupyter #notebook qtconsole jupyter_console
		# nbconvert
		# ipykernel ipywidgets
		# matplotlib
		pip

		];
     quarto = pkgs.quarto.overrideAttrs (oldAttrs: rec {
         preFixup = ''
          wrapProgram $out/bin/quarto \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.deno ]} \
            --prefix QUARTO_ESBUILD : ${pkgs.esbuild}/bin/esbuild \
            --prefix QUARTO_DART_SASS : ${pkgs.dart-sass}/bin/dart-sass \
            --prefix QUARTO_PYTHON : "${pkgs.python3.withPackages pythonDeps}/bin/python3" \
          '';
          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/share

            mv bin/* $out/bin
            mv share/* $out/share

            runHook postInstall
        '';
    });
in
    pkgs.mkShell {
        PYTHONPATH = "${pkgs.python3.withPackages pythonDeps}/bin/python3";
        QUARTO_PYTHON = "${pkgs.python3.withPackages pythonDeps}/bin/python3";
        QUARTO_PANDOC = "${quarto}/bin/tools/pandoc";
        packages = with pkgs; [ 
            nodePackages_latest.npm
            (python3.withPackages pythonDeps)
            quarto
            texlive.combined.scheme-full
            ];
    }
