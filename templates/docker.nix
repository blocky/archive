{ cmd, src, imageName, tagName }:
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
  };

  # in the final container, we will put the application executable
  # in the specified directory
  appDir = "app";

  # Ensure that the cmd list is not empty and get the command name
  cmdName = if cmd != [] then
    builtins.head cmd
  else
    builtins.throw "Error: The cmd list must contain at least one element.";

  # get the package for the go project that we are building
  goProj = import ./go.nix {
    pkgs = pkgs;
    src = src;
  };

  # When we built the go package, we may have built many executables.
  # Filter the executables so that we only copy the one we are interested in.
  slimGoProj = pkgs.stdenvNoCC.mkDerivation {
    name = "slim-go-proj";
    src = goProj + "/bin/";
    cmdName = cmdName;
    appDir = appDir;
    buildPhase = ''
      mkdir -p $out/$appDir
      cp $cmdName $out/$appDir
    '';
  };

  dockerCMD = [ "/${appDir}/${cmdName}" ] ++ builtins.tail cmd;

in pkgs.dockerTools.buildImage {
  name = "${imageName}";
  tag = "${tagName}";
  copyToRoot = [ slimGoProj ];
  config = { Cmd = dockerCMD; };
}
