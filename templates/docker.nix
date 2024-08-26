{ cmd, src, imageName, tagName }:
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
  };
  aPkg = import ./go.nix {
    pkgs = pkgs;
    src = src;
  };

  # Prefix the executable command (first element in the cmd list) with the
  # executable path
  cmdConfig = [ (aPkg + "/bin/" + builtins.elemAt cmd 0) ]
    ++ builtins.slice cmd 1 (builtins.length cmd);

in pkgs.dockerTools.buildImage {
  name = "${imageName}";
  tag = "${tagName}";
  copyToRoot = [ aPkg ];

  config = { Cmd = cmdConfig; };
}
