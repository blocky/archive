# archive

The larger goal of this project is to provide a way to produce byte-for-byte
identical archives independent of the platform on which the archive is
created.

Currently, however, it is highly opinionated in that it only supports working
in the shell described by `shell.nix` for a go project that has its
dependencies in the `vendor` folder.

## Getting started

Install the nix package manager on your system. See
[download](https://nixos.org/download/) for more info.  Note that while it does
take you to NixOS, this site just installs the package manager. You do NOT need
to run the OS.


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
