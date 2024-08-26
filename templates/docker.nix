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

  # Ensure that the cmd list is not empty and construct the cmdConfig
  cmdConfig = if builtins.length cmd < 1 then
    builtins.throw "Error: The cmd list must contain at least one element."
  else
  # Prefix the executable command (first element in the cmd list) with the
  # executable path, then append the rest of the cmd list
    [ (aPkg + "/bin/" + builtins.elemAt cmd 0) ]
    ++ builtins.slice cmd 1 (builtins.length cmd);

in pkgs.dockerTools.buildImage {
  name = "${imageName}";
  tag = "${tagName}";
  copyToRoot = [ aPkg ];

  config = { Cmd = cmdConfig; };
}
