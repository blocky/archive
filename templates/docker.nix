{ cmd, src, imageName, tagName }:
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
  aPkg = import ./go.nix { pkgs = pkgs; src = src; };
  cmdFromPkg = aPkg + "/bin/" + cmd;
in
pkgs.dockerTools.buildImage {
    name = "${imageName}";
    tag = "${tagName}";
    copyToRoot = [ aPkg ];

    config = {
        Cmd = [ "${cmdFromPkg}" ];
    };
}
