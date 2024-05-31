#!/bin/env bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <srcDir> <tarName>"
    exit 1
fi

srcDir=$1
dst=$(realpath $2)
tmpTar=/tmp/nitriding-archive.tar

cd "$srcDir"

tar \
    --exclude-vcs \
    --exclude-vcs-ignores \
    --exclude "$archiveTarFile" \
    --sort=name \
    --format=posix \
    --pax-option='exthdr.name=%d/PaxHeaders/%f' \
    --pax-option=delete=atime,delete=ctime \
    --clamp-mtime --mtime=@0 \
    --numeric-owner \
    --owner=0 \
    --group=0 \
    --mode='go+u,go-w' \
    -cf "$tmpTar" \
    ./vendor \
    .

tar \
    --append \
    --sort=name \
    --format=posix \
    --pax-option='exthdr.name=%d/PaxHeaders/%f' \
    --pax-option=delete=atime,delete=ctime \
    --clamp-mtime --mtime=@0 \
    --numeric-owner \
    --owner=0 \
    --group=0 \
    --mode='go+u,go-w' \
    --file="$tmpTar" \
    ./.gitignore

LC_ALL=c gzip -cn "$tmpTar" > "$dst"
