{ pkgs ? import <nixpkgs> { } }:

let
  python3 = pkgs.python311;
  pythonDeps = ps: with ps; [
    jupyter-core
    pyyaml
  ];

  texDeps = ps: with ps; [
    collection-latex
    collection-latexrecommended
    xetex
  ];

  quarto = pkgs.quarto.overrideAttrs (oldAttrs: rec {
    # 1.3 + newer (I think) has a weird bug with the text boxes where they are white on a black background. Readable, but ugly
    version = "1.5.47";
    src = pkgs.fetchurl {
      url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
      sha256 = "sha256-Zfx3it7vhP+9vN8foveQ0xLcjPn5A7J/n+zupeFNwEk=";
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

  packages = with pkgs; [
    (python3.withPackages pythonDeps)
    quarto
    (texlive.withPackages texDeps)
  ];
}
