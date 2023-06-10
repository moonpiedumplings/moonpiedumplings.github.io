{ pkgs ? import <nixpkgs> {} } :
let
    quarto = pkgs.quarto.overrideAttrs (oldAttrs: rec {
        version = "1.3.361";
        src = pkgs.fetchurl {
            url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
            sha256 = "sha256-vvnrIUhjsBXkJJ6VFsotRxkuccYOGQstIlSNWIY5nuE=";
        };
    });
    pandoc = pkgs.haskellPackages.pandoc_3_1_2.overrideScope (hfinal: hprev: {
        doctemplates = hprev.doctemplates_0_11;
        gridtables = hprev.gridtables_0_1_0_0;
        jira-wiki-markup = hprev.jira-wiki-markup_1_5_1;
        mime-types = hprev.mime-types_0_1_1_0;
        pandoc-types = hprev.pandoc-types_1_23;
        texmath = hprev.texmath_0_12_7_1;
        tasty-hslua = hprev.tasty-hslua_1_1_0;
        hslua-marshalling = hprev.hslua-marshalling_2_3_0;
        hslua-aeson = hprev.hslua-aeson_2_3_0_1;
        hslua = hprev.hslua_2_3_0;
      });
    pandoc-cli = pkgs.haskellPackages.pandoc-cli.overrideScope (hfinal: hprev: {
    	hslua-core = hprev.hslua-core_2_3_1;
    	lua = hprev.lua_2_3_1;
        tasty-hslua = hprev.tasty-hslua_1_1_0;
        hslua-marshalling = hprev.hslua-marshalling_2_3_0;
        hslua-aeson = hprev.hslua-aeson_2_3_0_1;
        hslua = hprev.hslua_2_3_0;
    });
in
    pkgs.mkShell {
        packages = [ pkgs.python310Full quarto pkgs.jupyter pandoc pandoc-cli pkgs.deno ];
    }
