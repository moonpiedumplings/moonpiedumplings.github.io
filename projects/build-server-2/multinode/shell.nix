{
    pkgs ? import <nixpkgs> {},
    pythonDeps ? ps: with ps; [ ansible ansible-core ]
} :
let
    python3WithAnsible = (pkgs.python311.withPackages pythonDeps);
in
pkgs.mkShell {
    #LC_ALL="en_US.UTF-8"; # Doesn't work. Idk why.
    LC_ALL="C.UTF-8";
    packages = with pkgs; [ 
            python3WithAnsible
        ];
}