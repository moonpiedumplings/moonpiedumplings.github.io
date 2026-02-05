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
    # preFixup = ''
    #   wrapProgram $out/bin/quarto \
    #     --set-default QUARTO_PANDOC ${pkgs.lib.makeBinPath [ pkgs.pandoc ]}/pandoc \
    #     --set-default QUARTO_TYPST ${pkgs.lib.makeBinPath [ pkgs.typst ]}/typst \
    #     --set-default QUARTO_ESBUILD ${pkgs.lib.makeBinPath [ pkgs.esbuild ]}/esbuild \
    #     --set-default QUARTO_DENO ${pkgs.lib.makeBinPath [pkgs.deno]}/deno \
    #     --set-default QUARTO_DART_SASS ${pkgs.lib.makeBinPath [pkgs.dart-sass]}/dart-sass
    # '';
    # patches = [
    # ];
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share

      rm -rf bin/tools/*
      rm -rf bin/tools/*

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
