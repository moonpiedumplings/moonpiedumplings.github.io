{ pkgs ? import <nixpkgs> {} } :
let
    quarto = pkgs.quarto.overrideAttrs (oldAttrs: rec {
        version = "1.3.361";
        src = pkgs.fetchurl {
            url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
            sha256 = "sha256-vvnrIUhjsBXkJJ6VFsotRxkuccYOGQstIlSNWIY5nuE=";
        };
    });
    doctemplates = pkgs.haskellPackages.doctemplates_0_11;
    gridtables = pkgs.haskellPackages.gridtables_0_1_0_0;
    jira-wiki-markup = pkgs.haskellPackages.jira-wiki-markup_1_5_1;
    mime-types = pkgs.haskellPackages.mime-types_0_1_1_0;
    pandoc-types = pkgs.haskellPackages.pandoc-types_1_23;
    texmath = pkgs.haskellPackages.texmath_0_12_7_1;
    #pandoc = pkgs.haskellPackages.pandoc_3_1_2.override {inherit doctemplates gridtables jira-wiki-markup mime-types pandoc-types texmath;};
    pandoc = pkgs.haskellPackages.callCabal2nix "pandoc" (fetchTarball {
    	url = "https://github.com/jgm/pandoc/archive/refs/tags/3.0.tar.gz";
    	sha256 = "1sqzhwlpl462cmh5qqxaai7v3jp38ghyrj3065nbfz8yipynmh2g";
    }) {inherit doctemplates gridtables jira-wiki-markup mime-types pandoc-types texmath;};
in
    pkgs.mkShell {
        packages = with pkgs; [ python310Full quarto jupyter pandoc deno mkpasswd ];
    }
