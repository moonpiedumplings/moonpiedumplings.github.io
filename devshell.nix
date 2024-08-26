{ pkgs ? import <nixpkgs> { } }:

let
  python3 = pkgs.python311;
  pythonDeps = ps: with ps; [
    jupyter-core
    pyyaml
    nbformat
    nbclient
    ipykernel
    requests
  ];

  texDeps = ps: with ps; [
    scheme-infraonly
    collection-latex
    collection-latexrecommended
    xetex
    fontawesome5
  ];
  texEnv = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-infraonly
      collection-latex collection-latexrecommended
      fontawesome5
      xetex;
  });

  quarto = pkgs.quarto.overrideAttrs (oldAttrs: rec {
    # 1.3 + newer (I think) has a weird bug with the text boxes where they are white on a black background. Readable, but ugly
    version = "1.5.56";
    src = pkgs.fetchurl {
      url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
      sha256 = "sha256-sq7/Jfwo//yMiK0JSN99HMnXswNP4vPElZIRmSb+R8g=";
    };
    preFixup = ''
      wrapProgram $out/bin/quarto \
        --prefix QUARTO_TYPST : ${pkgs.lib.makeBinPath [ pkgs.typst ]}/typst \
        --prefix QUARTO_ESBUILD ${pkgs.lib.makeBinPath [ pkgs.esbuild ]}/esbuild
    '';
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share

      rm -rf bin/tools/*/typst
      rm -rf bin/tools/*/esbuild

      mv bin/* $out/bin
      mv share/* $out/share

      runHook postInstall
    '';
  });

in
pkgs.mkShellNoCC {
  PYTHONPATH = "${pkgs.python3.withPackages pythonDeps}/bin/python3";
  QUARTO_PYTHON = "${pkgs.python3.withPackages pythonDeps}/bin/python3";
  # LOCALE_ARCHIVE_2_39 = "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive";
  # LANGUAGE = "en_US.UTF-8";
  # LC_ALL = "en_US.UTF-8";
  # LOCALE_ARCHIVE_2_39 = "/usr/lib/locale/locale-archive";
  # LOCALE_ARCHIVE = "/usr/lib/locale/locale-archive";

  packages = with pkgs; [
    bashInteractive
    (python3.withPackages pythonDeps)
    quarto
    # (texlive.withPackages texDeps)
    texEnv
    font-awesome
  ];

   shellHook = ''
    export SHELL='${pkgs.bashInteractive}/bin/bash'
  '';
}
