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
     # 1.3 + newer (I think) has a weird bug with the text boxes where they are white on a black background. Readable, but ugly
     version = "1.5.24";
          src = pkgs.fetchurl {
              url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
              sha256 = "sha256-JRcuD2fwLfGohyOhh5EmNRrDaNMEHOi0r4+newHRIFw=";
          };
#       version = "1.4.551";
#           src = pkgs.fetchurl {
#               url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
#               sha256 = "sha256-RUnlLjJOf8hSj7aRCrmDSXFeNHCXnMY/bdbE3fbbThQ=";
#           };
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

        # This will warn if not on an x68_64 system, but still work. 
        # Too lazy to figure out how to get the current architecture in Nix for now, especially since this is currenntly non-breaking. 
        QUARTO_PANDOC = "${quarto}/bin/tools/x86_64/pandoc";
        packages = with pkgs; [ 
            nodePackages_latest.npm
            (python3.withPackages pythonDeps)
            quarto
            texlive.combined.scheme-full
            ];
    }
