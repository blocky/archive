{ pkgs ? import <nixpkgs> {}, src }:
let buildGoModule = pkgs.buildGoModule;
    lib = pkgs.lib;
    pkgSrc = src;
in
(buildGoModule rec {
  pname = "go-proj";
  version = "v0.0.1";

  # this is the path to the thing we are going to build.
  # For now, this is a relative path, however, it
  # will likely be:
  # - a url (use fetchurl)
  # - a git repo (use fetchgit)
  # - a tarball (use fetchtarball)
  src = pkgSrc;

  # This value can be the hash of the vendor library or null
  # When it is null, we must provide the vendor library.
  # Since we want to package the dependencies with our applications
  # vendor should always be set to null
  vendorHash = null;

  # Do not user cgo
  CGO_ENABLED = 0;

  # I am still trying to figure out what this really does. In general, when it
  # is set to false, the check phase of building is skipped.  From a few
  # non-authoritative sources, it seems that the do check for go building is
  # running the tests (I am guessing that is by running `go test ./...` but I
  # have not confirmation of that) )
  doCheck = false;

  meta = with lib; {
    description = "A demo go applicaton";
    homepage = "https://blocky.rocks";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
