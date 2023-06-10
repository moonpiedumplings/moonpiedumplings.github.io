let
  nixpkgs-src = fetchTarball {
    # nixpkgs-unstable as of 2023-05-31
    url = "https://github.com/NixOS/nixpkgs/archive/58c85835512b0db938600b6fe13cc3e3dc4b364e.tar.gz";
    sha256 = "0bkhaiaczj25s6hji2k9pm248jhfbiaqcfcsfk92bbi7kgzzzpif";
  };

  my-overlay = final: prev: {

    pandoc_1_3 =
      let
        inherit (final.haskell.lib.compose) disableCabalFlag markUnbroken;
      in
      final.lib.pipe
        final.haskellPackages.pandoc-cli
        [
          markUnbroken
          (disableCabalFlag "lua")
          (p: p.overrideScope (hfinal: hprev: {
            doctemplates = hprev.doctemplates_0_11;
            gridtables = hprev.gridtables_0_1_0_0;
            hslua-cli = null;
            jira-wiki-markup = hprev.jira-wiki-markup_1_5_1;
            mime-types = hprev.mime-types_0_1_1_0;
            pandoc = hprev.pandoc_3_1_2;
            pandoc-lua-engine = null;
            pandoc-server = markUnbroken hprev.pandoc-server;
            pandoc-types = hprev.pandoc-types_1_23;
            texmath = hprev.texmath_0_12_7_1;
          }))
        ];

    quarto_1_3 =
      let
        quarto-version = "1.3.361";
      in
      (final.quarto.override { pandoc = final.pandoc_1_3; }).overrideAttrs (oldAttrs: {
        version = quarto-version;
        src = final.fetchurl {
          url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${quarto-version}/quarto-${quarto-version}-linux-amd64.tar.gz";
          sha256 = "sha256-vvnrIUhjsBXkJJ6VFsotRxkuccYOGQstIlSNWIY5nuE=";
        };
      });
  };

  pkgs = import nixpkgs-src { overlays = [ my-overlay ]; };

in
	pkgs.mkShell {
		packages = [ pkgs.quarto_1_3 ];
		}
