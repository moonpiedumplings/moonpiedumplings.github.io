{
    pkgs ? import <nixpkgs> {},
    
} :
let 
    okeystone = pkgs.callPackage ./keystone.nix {};
in
    pkgs.mkShell {
        packages = with pkgs; [ okeystone ];
    }
