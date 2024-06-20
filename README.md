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
./archive.sh go-proj ../set-get > /tmp/set-get-src.tgz
```

Let's break this down:

* `./archive.sh go-proj` runs the subcommand
* `../set-get` is the path to the `set-get` project > /tmp/src.tgz
* `> /tmp/src.tgz` outputs the gzipped tarball to `/tmp/src.tgz`

Now that we have an archive, we can use the other command to create a package
that acts as a way to build the EIF file, and archive the source so that one
can compute PCR0s in the future.

```bash
./archive.sh package ../assets /tmp/set-get-src.tgz set-get "gateway"
```

Let's break this down:
* `./archive.sh package` runs the subcommand
* `../assets` is the place where we will place our outputs, note that we assume
  that the directory does not yet exist
* `/tmp/set-get-src.tgz` is the source archive.  We created that in the
  previous step.
* `set-get` is the name of the project
* `gateway` is the name of the program created by the project.  That is, it is
  the name of the program created by running `go install .` in the project
  directory.  You can find it in the go.mod file.

Once this runs, all of your assets will be in the `../assets` directory.

And for the big finish, you can "verify" this archive as follows:

```bash
cd ../assets
tar -xzf set-get.tar.gz
cd set-get
make
```
The `output` folder will hold the eif file and the `eif-description.json` file.
You can find the PCR0 from the desciption as follows:

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

You will likely observe that the tests fail.  That is because, you will
need to run in a nix shell for everything to be reproducible.

To start a pure nix shell (that is, none of your host's environment will leak
into the shell) run:

```bash
nix-shell --pure
```

And now, the tests should succeed

```bash
make test
```

## Example usage

We provide two examples of how to use this tool to generate a gzipped
tarball of a specific commit of a project.

First, let's get a starting point. Somewhere on your system, run:

```bash
git clone https://github.com/blocky/nitriding
git checkout 971dd68
cd nitriding
dataDir=$(pwd)
```

After appropriate setup for nitriding, we can find the expected `md5sum` of the
gzipped tarball using the following commands:

```bash
mage source:all
md5sum ./static/assets/source.tar.gz | awk '{print $1}'
```

This will produce `737ba8540fcee07cce2bb06cb132f39c`

Second, let's use the `archive` tool to produce the same result.  From the root
directory of this project run:

```bash
./archive.sh "$dataDir" "source.tar"
```

This will create a gzipped tarball current directory called `source.tar.gz`.
Let's check the hash of this file:

```bash
md5sum ./source.tar.gz | awk '{print $1}'
```

If you got `737ba8540fcee07cce2bb06cb132f39c`, then the tool is working as
expected.

Third, you can run the archive tool via docker. This is useful if you are on a
Mac (or another system without the gnu tar).  Build the image and
tag it with a useful name

```bash
docker build -t archive .
```

Run the image mapping `$dataDir` (from the host) to `/data` (in the container):

```bash
docker run -v $dataDir:/data archive /data /data/static/assets/source-docker.tar
```

This will create `source-docker.tar.gz` file in the `static/assets` folder of
`$dataDir`. We can check that the hash of this file as well:

```bash
md5sum $dataDir/static/assets/source-docker.tar.gz | awk '{print $1}'
```
If you got `737ba8540fcee07cce2bb06cb132f39c`, then the tool is working as
expected.

## Developing

While there is really not much to this project, it was helpful to use
[bats](https://bats-core.readthedocs.io) to get everything going and so I left
it in the project to aid in later development, should we need more.
