{ cmd, src, imageName, tagName }:
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs { config = {}; overlays = []; };
  aPkg = import ./go.nix { pkgs = pkgs; src = src; };
  cmdFromPkg = aPkg + "/bin/" + builtins.head cmd;

  cmdTail = builtins.tail cmd;
  cmdConfig = if builtins.length cmdTail > 0 then
    [ "${cmdFromPkg}" ] ++ cmdTail
  else
    [ "${cmdFromPkg}" ];

in
pkgs.dockerTools.buildImage {
    name = "${imageName}";
    tag = "${tagName}";
    copyToRoot = [ aPkg ];

    config = {
        Cmd = cmdConfig;
    };
}
