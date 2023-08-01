
{ stdenv
, lib
, esbuild
, deno
, fetchurl
, nodePackages
, rWrapper
, rPackages
, extraRPackages ? []
, makeWrapper
, python3
, extraPythonPackages ? ps: with ps; []
}:

stdenv.mkDerivation rec {
  pname = "quarto";
  version = "1.3.361";
        src = fetchurl {
            url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
            sha256 = "sha256-vvnrIUhjsBXkJJ6VFsotRxkuccYOGQstIlSNWIY5nuE=";
        };

  nativeBuildInputs = [
    makeWrapper
  ];

  patches = [
    ./fix-deno-path.patch
  ];

  postPatch = ''
    # Compat for Deno >=1.26
    substituteInPlace bin/quarto.js \
      --replace 'Deno.setRaw(stdin.rid, ' 'Deno.stdin.setRaw(' \
      --replace 'Deno.setRaw(Deno.stdin.rid, ' 'Deno.stdin.setRaw('
  '';

  dontStrip = true;

  preFixup = ''
            wrapProgram $out/bin/quarto \
            --prefix PATH : ${lib.makeBinPath [ deno ]} \
            --prefix QUARTO_PANDOC : $out/bin/tools/pandoc \
            --prefix QUARTO_ESBUILD : ${esbuild}/bin/esbuild \
            --prefix QUARTO_DART_SASS : $out/bin/tools/dart-sass/sass \
            --prefix QUARTO_R : ${rWrapper.override { packages = [ rPackages.rmarkdown ] ++ extraRPackages; }}/bin/R \
    '';
    #            --prefix QUARTO_PYTHON : ${python3}/bin/python3

  installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/share

            mv bin/* $out/bin
            mv share/* $out/share

            runHook preInstall
            '';

  meta = with lib; {
    description = "Open-source scientific and technical publishing system built on Pandoc";
    longDescription = ''
        Quarto is an open-source scientific and technical publishing system built on Pandoc.
        Quarto documents are authored using markdown, an easy to write plain text format.
    '';
    homepage = "https://quarto.org/";
    changelog = "https://github.com/quarto-dev/quarto-cli/releases/tag/v${version}";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ mrtarantoga ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode binaryBytecode ];
  };
}
