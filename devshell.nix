{
  pkgs ? import <nixpkgs> { },
}:

let
  python3 = pkgs.python314;
  pythonDeps =
    ps: with ps; [
      jupyter-core
      pyyaml
      nbformat
      nbclient
      ipykernel
      requests
    ];

  #pkgs.pandoc = pandoc-flake.packages.x86_64-linux."pandoc-cli\:exe\:pandoc";

  texEnv = (
    pkgs.texlive.combine {
      inherit (pkgs.texlive)
        scheme-infraonly
        collection-latex
        collection-latexrecommended
        # fontawesome6
        lualatex-math
        luatex
        framed
        xetex
        # Stuff needed for Jake's resume template
        preprint
        titlesec
        marvosym
        enumitem
        fancyhdr
        # Not strictly needed for jakes, but makes things easier via a script
        latexmk
        ;
    }
  );

  quarto = pkgs.quarto.overrideAttrs (oldAttrs: rec {

    pname = "quarto";
    version = "1.9.38";

    src = pkgs.fetchurl {
      url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
      hash = "sha256-6oyJc2h5GtnyAAEMCH6jERsuVWsSqWBIfdTiFpAqoQI=";
    };

    postFixup = ''
           substituteInPlace $out/bin/quarto.js \
             --replace-fail 'kSyntaxHighlighting = "syntax-highlighting"' 'kSyntaxHighlighting = "highlight-style"' \
             --replace-fail '"--syntax-highlighting"' '"--highlight-style"'
           substituteInPlace $out/share/filters/modules/jog.lua \
             --replace-fail "elseif tp == 'pandoc TableHead' or tp == 'pandoc TableFoot' or" "elseif tp == 'pandoc TableBody' or tp == 'TableBody' then
        element.head = jogger(element.head)
        element.body = jogger(element.body)
      elseif tp == 'pandoc TableHead' or tp == 'pandoc TableFoot' or"
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share

      rm -r bin/tools/*

      mkdir bin/tools/aarch64
      mkdir bin/tools/x86_64

      ln -s ${pkgs.lib.makeBinPath [ pkgs.pandoc ]}/pandoc bin/tools/x86_64/pandoc
      ln -s ${pkgs.lib.makeBinPath [ pkgs.pandoc ]}/pandoc bin/tools/aarch64/pandoc


      mv bin/* $out/bin
      mv share/* $out/share

      runHook postInstall
    '';
  });

in
pkgs.mkShellNoCC {
  PYTHONPATH = "${pkgs.python3.withPackages pythonDeps}/bin/python3";
  QUARTO_PYTHON = "${pkgs.python3.withPackages pythonDeps}/bin/python3";

  packages = with pkgs; [
    bashInteractive
    (python3.withPackages pythonDeps)
    quarto
    pandoc
    texEnv
    font-awesome
  ];

  shellHook = ''
    export SHELL='${pkgs.bashInteractive}/bin/bash'
  '';
}
