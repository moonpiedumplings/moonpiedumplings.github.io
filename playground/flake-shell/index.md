---
title: "Creating a nix flake, the \"proper\" way"
date: "2024-6-4"
categories: [nix]
# draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---

So, I think it's time for me to move from the older channels way of doing things in nix, to the newer flakes. However, the nix docs are very poor, so I am going to document my process of converting my development environment here. 

The first thing, is that despite the fact that there is a lot of the existing flakes use a utility called [flake-utils](). However, this tool was ultimately started as an experiment, and has issues. A [blog post](https://ayats.org/blog/no-flake-utils/) ([archive](https://web.archive.org/web/20240229094244/https://ayats.org/blog/no-flake-utils/)) goes over some of the issues it has, and recommends against it... except I can't figure out at all how to apply it. 

The other recommendation is another pattern, recommended by Reddit user Tomberek:

```{.nix}
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/22.05";
  outputs = {self,nixpkgs}: {
    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        shellHook = ''
          echo 'WARNING: gotcha during nix develop shellHooks'
          function _direnv_hook(){
              echo 'WARNING, "_direnv_hook" has been overwritten"'
          }
        '';
        packages = [
          (pkgs.writeShellApplication {
            name = "ls";
            text = ''
              echo 'WARNING, "ls" has been overwritten"'
            '';
          }
            )
        ];
      };
    }) nixpkgs.legacyPackages;
  };
}
```

There are multiple different ways of creating an output for multiple systems at once, it seems. 

So far:

* ForEachSystem
* Flake-parts
* Flake-utils
* Tombereks' method

I suspect there are other methods, potentially better one's, that aren't documented. 

My ultimate goal is to convert the shell.nix I am using, into a flake. 