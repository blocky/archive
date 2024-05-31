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
    --mtime=@0 \
    --numeric-owner \
    --owner=0 \
    --group=0 \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    -cf "$tmpTar" \
    ./vendor \
    .

tar \
    --append \
    --sort=name \
    --mtime=@0 \
    --numeric-owner \
    --owner=0 \
    --group=0 \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    --file="$tmpTar" \
    ./.gitignore

LC_ALL=c gzip -cn "$tmpTar" > "$dst"
