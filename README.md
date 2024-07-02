# archive

The larger goal of this project is to provide a way to produce byte-for-byte
identical archives independent of the platform on which the archive is created.

Currently, however, it is highly opinionated in that it only supports working
in `nix shell` with go projects that build from a main file in the root (e.g.
`go install .`) with dependencies in the `vendor` folder.

## Getting started

Install the nix package manager on your system. See
[download](https://nixos.org/download/) for more info.  Note that while it does
take you to NixOS, this site just installs the package manager. You do NOT need
to run the OS.

Install docker on your system.  You will need to run docker locally (not just
though nix)

## Sample usage

There are two main commands:
1. `./archive.sh go-proj` for archiving go projects that have a vendor folder.
2. `./archive.sh package` for creating build artifacts.

First, let's create an archive of a go project.  Clone the project and create
the vendor folder.  Since you have nix installed, you don't even need to worry
about setting up a go environment.  Just run the following commands:

```bash
nix-shell -p go git
git clone https://github.com/blocky/set-get
cd set-get
go mod vendor
exit
```

Here, we will assume that the project is in the `set-get` directory next to the
`archive` directory. That is, the directory structure looks like this:

```
$ ls
archive  set-get
```

Next, we can run the archive command to produce a gzipped tarball of the
set-get project.

```bash
cd archive
./archive.sh go-proj ../set-get > /tmp/set-get-src.tgz
```

Let's break this down:

* `./archive.sh go-proj` runs the subcommand
* `../set-get` is the path to the `set-get` project
* `> /tmp/set-get-src.tgz` outputs the gzipped tarball to `/tmp/set-get-src.tgz`

Now that we have an archive, we can use the other command to create a package
that acts as a way to build the EIF file, and archive the source so that one
can compute PCR0s in the future.

```bash
./archive.sh package /tmp/set-get-assets /tmp/set-get-src.tgz set-get "gateway"
```

Let's break this down:
* `./archive.sh package` runs the subcommand
* `/tmp/set-get-assets` is the place where we will place our outputs. We assume
  that the directory does not yet exist
* `/tmp/set-get-src.tgz` is the source archive.  We created that in the
  previous step.
* `set-get` is the name of the project
* `gateway` is the command to start the executable produced by installing the
  set-get project.  That is, it is the name of the program created by running
  `go install .` in the project directory.  You can find that info in the
  go.mod file.

Once this runs, all of your assets will be in the `/tmp/set-get-assets` directory.

And for the big finish, you can "verify" this archive as follows:

```bash
cd /tmp/set-get-assets
tar xzf set-get.tar.gz
cd set-get
make
```
The `output` folder will hold the eif file and the `eif-description.json` file.
You can find the PCR0 from the description as follows:

```bash
cd ouput
jq .Measurements.PCR0 eif-description.json
```

## Getting started developing

Testing is done with [bats](https://bats-core.readthedocs.io).  Bats is set up
as a submodule, so you can get it set up with:

```bash
git submodule update --init
```

You can run the tests with

```bash
make test
```

You will likely observe that starting the application is kind of slow.  This is
because each run of the `archive.sh` script will start a `nix-shell`.  There is
likely a better way, but at least one thing that helps is you can speed up
development by starting a `nix-shell`, updating the script and developing the
script in the `nix-shell`.  For example

```bash
nix-shell --pure -p bash docker mustache-go nix
```

And then go to `archive.sh` add a "normal" bash shebang. That is, apply the
following patch (just make sure to remove it before committing):

```
--- a/archive.sh
+++ b/archive.sh
@@ -1,3 +1,5 @@
+#!/usr/bin/env bash
+
#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure
#! nix-shell -p bash mustache-go nix cacert docker
```
