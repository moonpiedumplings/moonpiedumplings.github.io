{ pkgs ? import <nixpkgs> { } }:

let
  python3 = pkgs.python311;
  pythonDeps = ps: with ps; [
    # qtconsole
    # jupyter-console
    # ipykernel
    jupyter-core
    # nbconvert
    # ipython
    # notebook ipywidgets
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
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.deno ]} \
          --prefix QUARTO_ESBUILD : ${pkgs.esbuild}/bin/esbuild \
          --prefix QUARTO_DART_SASS : ${pkgs.dart-sass}/bin/dart-sass \
          --prefix QUARTO_DENO : ${pkgs.lib.makeBinPath [ pkgs.deno ]}/deno \
          --prefix QUARTO_TYPST : ${pkgs.lib.makeBinPath [ pkgs.typst ]}/typst \
    '';
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share

      rm -rf bin/tools/*/dart*
      rm -rf bin/tools/*/deno*
      rm -rf bin/tools/*/typst

      mv bin/* $out/bin
      mv share/* $out/share

      runHook postInstall
    '';
  });
in
# pkgs.mkShell {
pkgs.mkShellNoCC {
  PYTHONPATH = "${pkgs.python3.withPackages pythonDeps}/bin/python3";
  QUARTO_PYTHON = "${pkgs.python3.withPackages pythonDeps}/bin/python3";

  #LANGUAGE = "en_US.UTF-8";
  #LC_ALL = "en_US.UTF-8";

  packages = with pkgs; [
    (python3.withPackages pythonDeps)
    quarto
    (texlive.withPackages texDeps)
  ];
}
