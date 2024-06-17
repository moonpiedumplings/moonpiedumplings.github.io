{ pkgs ? import <nixpkgs> {} }:

let
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
     version = "1.5.25";
          src = pkgs.fetchurl {
              url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
              sha256 = "sha256-Gg8cMnF54C4WHwYjY6vOrgOexKLqy9/S+wC0B6qIO+8=";
          };
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

        packages = with pkgs; [ 
            nodePackages_latest.npm
            (python3.withPackages pythonDeps)
            quarto
            texlive.combined.scheme-full
            ];
    }
