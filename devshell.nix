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
  
  texEnv = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-infraonly
      collection-latex collection-latexrecommended
      fontawesome6
      lualatex-math
      luatex
      framed
      xetex;
  });

  quarto = pkgs.quarto.overrideAttrs (oldAttrs: rec {
    version = "1.8.25";
    src = pkgs.fetchurl {
      url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
      sha256 = "sha256-E9RDAooKgnshdXs3+etS26+PBiPr/KxEFi++o62fwf8=";
    };
    preFixup = ''
      wrapProgram $out/bin/quarto \
        --prefix QUARTO_TYPST : ${pkgs.lib.makeBinPath [ pkgs.typst ]}/typst \
        --prefix QUARTO_ESBUILD ${pkgs.lib.makeBinPath [ pkgs.esbuild ]}/esbuild
    '';
    patches = [
    ];
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

  packages = with pkgs; [
    bashInteractive
    (python3.withPackages pythonDeps)
    quarto
    texEnv
    font-awesome
  ];

   shellHook = ''
    export SHELL='${pkgs.bashInteractive}/bin/bash'
  '';
}
