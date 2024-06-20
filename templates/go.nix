{ pkgs ? import <nixpkgs> {}, src }:
let buildGoModule = pkgs.buildGoModule;
    lib = pkgs.lib;
    pkgSrc = src;
in
(buildGoModule rec {
  pname = "go-proj";
  version = "v0.0.0";

  # this is the path to the thing we are going to build.
  # For now, this is a relative path, however, it
  # will likely be:
  src = pkgSrc;

  # This value can be the hash of the vendor library or null
  # When it is null, we must provide the vendor library.
  # Since we want to package the dependencies with our applications
  # vendor should always be set to null
  vendorHash = null;

  # Do not use cgo
  CGO_ENABLED = 0;

  # skip running go tests.  Since this tools is just for packaging,
  # testing is up to the user.
  doCheck = false;

  meta = with lib; {
    description = "A reproducably packaged go applicaton";
    homepage = "https://blocky.rocks";
    platforms = platforms.unix;
  };
})
