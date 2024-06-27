#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure
#! nix-shell -p bash mustache-go nix cacert docker jq
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/tarball/nixos-24.05

set -e

function sub_help() {
    local app_name="$1"

    echo "Usage: $app_name [-u|--unsafe] <subcommand> [options]"
    echo ""
    echo "Flags:"
    echo "    -h, --help    Display the help message."
    echo "    -u, --unsafe  Allow running on an unsupported platform."
    echo ""
    echo "Subcommands:"
    echo "    help        Display the help message."
    echo "    package     Package for building for enclaves."
    echo "    go-proj     Archive a vendored go project maintained by git."
    echo "    repro-tar   tar with flags set for creating archives reproducibly."
    echo "                Additional options are passed through to the tar command."
    echo "    repro-gzip  gzip with flags set for compressing archives reproducibly."
    echo "                Additional options are passed through to the tar command."
}

function sub_repro-tar() {
    # SOURCE_DATE_EPOCH is a standard environment variable
    # for reproducible builds to use as a build time.
    # for more on this environment variable see:
    #   https://reproducible-builds.org/docs/timestamps/
    mtime=${SOURCE_DATE_EPOCH:=0}

    # A set of arguments for tar that will create reproducible archives.
    # For more on what these do and how they work see:
    #   https://www.gnu.org/software/tar/manual/html_node/Reproducibility.html
    #
    # One difference is that here, we do not set LC_ALL=C. From what I
    # understand, since nix controls the locals it should not be set by the
    # command.
    tar \
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

function sub_repro-gzip() {
    # A set of arguments for gzip that will create reproducible zips.
    # For more on what these do and how they work see:
    #   https://www.gnu.org/software/tar/manual/html_node/Reproducibility.html
    #
    # One difference is that here, we do not set LC_ALL=C. From what I
    # understand, since nix controls the locals it should not be set by the
    # command.
    gzip --no-name $@
}

function sub_go-proj() {
    local go_proj_dir=$1

    local proj_name=$(basename $go_proj_dir)
    local root_dir=$(dirname $go_proj_dir)

    ./archive.sh repro-tar \
            -C "$root_dir" \
            --exclude-vcs \
            --exclude-vcs-ignores \
            -c \
            "./$proj_name" \
            "./$proj_name/vendor" |
        ./archive.sh repro-gzip -c --best
}

function sub_package() {
    if [[ $# -lt 4 ]]; then
        echo "Usage: $0 package <dst> <src> <name> <cmd>"
        echo ""
        echo "    dst  Output directory. We assume it does not already exist"
        echo "    src  Source archive (created with go-proj subcommand)"
        echo "    name Name of the project"
        echo "    cmd  Name of the program created by the project"
        exit 1
    fi

    local dst=$1
    local src=$2
    local root_dir_name=$3
    shift 3
    local cmd=$@

    local tmp_dir=$(mktemp -d -t archive-package.XXXXXX)
    local staging_dir="$tmp_dir/$root_dir_name"

    # copy the boring templates
    local to_copy=( "docker.nix" "go.nix" "nitro-cli.dockerfile" )
    for f in "${to_copy[@]}"; do
        install -D "./templates/$f" "$staging_dir/$f"
    done

    # render the more interesting templates
    echo CMD: "$cmd" | mustache ./templates/Makefile.mustache > "$staging_dir/Makefile"

    # copy the source code
    local ext=$(echo "${src##*.}")
    cp -r "$src" "$staging_dir/src.$ext"

    # set everything to the right permissions
    chmod -R 644 $staging_dir/*

    # create the archive
    sub_repro-tar -c -C "$tmp_dir" "$root_dir_name" | \
        sub_repro-gzip -c --best > "$tmp_dir/$root_dir_name.tar.gz"

    # clean up
    rm -rf $staging_dir

    # now we build our artifacts from the archive
    (cd $tmp_dir && \
        tar xzf "$root_dir_name.tar.gz" && \
        make -C "$root_dir_name" && \
        mv "$root_dir_name.tar.gz" "$root_dir_name/output/")

    # and put them in the final destination
    mv "$tmp_dir/$root_dir_name/output" $dst

    # clean up
    rm -rf $tmp_dir
}


function check_platform() {
    local allow_unchecked_platform="$1"
    local abort=false

    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    # check if we are running in nix-shell
    if [[ $IN_NIX_SHELL != "pure" ]]; then
        if $allow_unchecked_platform; then
            echo -e ${YELLOW}
            echo "WARNING:"
        else
            abort=true
            echo -e ${RED}
            echo "ERROR:"
        fi
        echo "    This script is designed to be run in a pure nix shell."
        echo "    While it may work, running outside of a pure nix shell"
        echo "    may be non-reproducible."
        echo ""
        echo "    IN_NIX_SHELL is set to '$IN_NIX_SHELL'."
        echo -e ${NC}
    fi

    # check if we are running on x86_64
    local arch=$(uname -m)
    if [[ $arch != "x86_64" ]]; then
        if $allow_unchecked_platform; then
            echo -e ${YELLOW}
            echo "WARNING:"
        else
            abort=true
            echo -e ${RED}
            echo "ERROR:"
        fi
        echo "    This script is designed to be run on the x86_64 arch."
        echo "    While it may work, running on different architectures"
        echo "    may be non-reproducible."
        echo ""
        echo "    arch is detected as '$arch'."
        echo -e ${NC}
    fi

    if $abort; then
        echo "Aborting:"
        echo "    You are running with an unchecked configuration."
        echo "    If you really want to run this application, "
        echo "    consider using the '--unsafe' flag."
        echo "    For example:"
        echo "        '$app_name --unsafe help'"
        exit 1
    fi
}

function main() {
    # General structure for handling bash subscommands
    # was prposed by waylan in the following gist:
    # https://gist.github.com/waylan/4080362
    app_name=$(basename $0)

    # this value controls whether we error or warn on a platform that
    # is not supported.
    allow_unchecked_platform=false

    while true; do
        opt=$1
        case $opt in
            "" | "-h" | "--help")
                sub_help $app_name
                exit 0
                ;;
            "-u" | "--unsafe")
                shift
                allow_unchecked_platform=true
                ;;
            *)
                shift
                check_platform $allow_unchecked_platform
                sub_${opt} $@
                if [ $? = 127 ]; then
                    echo "Error: '$subcommand' is not a known subcommand." >&2
                    echo "       Run '$app_name --help' for a list of known subcommands." >&2
                    exit 1
                fi
                exit 0
                ;;
        esac
    done
}

main "$@"
