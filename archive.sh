#!/bin/env bash

set -e

# General structure for handling bash subscommands
# was prposed by waylan in the following gist:
# https://gist.github.com/waylan/4080362
appName=$(basename $0)

sub_help(){
    echo "Usage: $appName <subcommand> [options]"
    echo ""
    echo "Subcommands:"
    echo "    repro-tar   tar with flags set for creating archives reproducibly."
    echo "                Additional options are passed through to the tar command."
    echo "    repro-gzip  gzip with flags set for compressing archives reproducibly."
    echo "                Additional options are passed through to the tar command."
    echo ""
    echo "For help with each subcommand run:"
    echo "$appName <subcommand> -h|--help"
    echo ""
    echo ""
}

function sub_repro-tar(){
    # SOURCE_DATE_EPOCH is a standard environment variable
    # for reproducible builds to use as a build time.
    # for more on this environment variable see:
    #   https://reproducible-builds.org/docs/timestamps/
    mtime=${SOURCE_DATE_EPOCH:=0}


    # A set of arguments for tar that will create reproducible archives.
    # For more on what these do and how they work see:
    #   https://www.gnu.org/software/tar/manual/html_node/Reproducibility.html
    LC_ALL=c tar \
        --sort=name \
        --format=posix \
        --pax-option='exthdr.name=%d/PaxHeaders/%f' \
        --pax-option=delete=atime,delete=ctime \
        --clamp-mtime \
        --mtime=@${mtime} \
        --numeric-owner \
        --owner=0 \
        --group=0 \
        --mode='go+u,go-w' \
        $@
}

sub_gzip(){
    LC_ALL=c gzip --no-name
}

subcommand=$1
case $subcommand in
    "" | "-h" | "--help")
        sub_help
        ;;
    *)
        shift
        sub_${subcommand} $@
        if [ $? = 127 ]; then
            echo "Error: '$subcommand' is not a known subcommand." >&2
            echo "       Run '$appName --help' for a list of known subcommands." >&2
            exit 1
        fi
        ;;
esac
