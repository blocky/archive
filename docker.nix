{ cmd, imageName, src }:
let
  pkgs = import <nixpkgs> { };
  aPkg = import ./go.nix { pkgs = pkgs; src = src; };
  cmdFromPkg = aPkg + "/bin/" + cmd;
in
pkgs.dockerTools.buildImage {
    name = "${imageName}";
    copyToRoot = [ aPkg ];

    config = {
        Cmd = [ "${cmdFromPkg}" ];
    };
}
