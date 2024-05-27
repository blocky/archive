# archive

The larger goal of this project is to provide a way to produce byte-for-byte
identical archives independent of the platform on which the archive is
created.

Currently, however, it is highly opinionated in that it only supports go
projects that use `git` for source control management and have its dependencies
in the `vendor` folder.

## Example usage

We provide two examples of how to use this tool to generate a gzipped
tarball of a specific commit of a project.

First, let's get a starting point. Somewhere on your system, run:

```bash
git clone https://github.com/blocky/nitriding
git checkout 971dd68
dataDir=$(pwd)
```

After appropriate setup for nitriding, we can find the expected `md5sum` of the
gzipped tarball using the following commands:

```bash
mage source:all
md5sum ./static/assets/source.tar.gz | awk '{print $1}'
```

This will produce `1340160b17e179b9add047aebef13a39`.

Second, let's use the `archive` tool to produce the same result.

```bash
./archive.sh "$dataDir" "source.tar"
```

This will create a gzipped tarball current directory called `source.tar.gz`.
Let's check the hash of this file:

```bash
md5sum ./source.tar.gz | awk '{print $1}'
```

If you got `1340160b17e179b9add047aebef13a39`, then the tool is working as
expected.

Third, you can run the archive tool via docker. This is useful if you are on a
Mac (or someother system without the gnu version of tar).  Build the image and
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
If you got `1340160b17e179b9add047aebef13a39`, then the tool is working as
expected.

## Developing

While there is really not much to this project, it was helpful to use
[bats](https://bats-core.readthedocs.io) to get everything going and so I left
it in the project to aid in later development, should we need more.
