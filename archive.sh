#!/bin/env bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <srcDir> <tarName>"
    exit 1
fi

srcDir=$1
tarName=$2

dst=$(realpath $tarName)

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
    -cf "$dst" \
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
    --file="$dst" \
    ./.gitignore

gzip -nf "$dst"
