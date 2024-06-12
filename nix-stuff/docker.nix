{ appDotNix, cmd, dockerImageName, dockerImageTag }:
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
  aPkg = import appDotNix { pkgs = pkgs; };
  cmdFromPkg = aPkg + cmd;
in
pkgs.dockerTools.buildImage {
    name = "${dockerImageName}";
    tag = "${dockerImageTag}";
    copyToRoot = [ aPkg ];

    config = {
        Cmd = [ "${cmdFromPkg}" ];
    };
}
