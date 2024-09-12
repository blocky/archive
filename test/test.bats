
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/..:$PATH"
}

@test "error path - not enough arguments archiving project" {
    run ./archive.sh go-proj
    assert_failure
}

@test "error path - empty arguments not allowed archiving project" {
    run ./archive.sh go-proj ''
    assert_failure
}

@test "error path - not enough arguments packaging project" {
    run ./archive.sh package arg1 arg2 arg3
    assert_failure
}

@test "error path - empty arguments not allowed packaging project" {
    run ./archive.sh package arg1 arg2 arg3 ''
    assert_failure
}

@test "happy path - expected hash of archive does not change" {
    # the expected hash came from running:
    #
    #   ./archive.sh reproducible-tar -C ./test/test_data/ --exclude-vcs --exclude-vcs-ignores -c ./go_proj/ ./go_proj/vendor | md5sum
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="f6e86ff1ae4c423cf7da4acb4edb5421"

    got=$(./archive.sh reproducible-tar \
        `# use the test data directory as the base directory` \
        -C ./test/test_data/ \
        `# exclude the .git and other git related files, e.g. .gitignore` \
        --exclude-vcs \
        `# exclude anything that would be ignored by git` \
        --exclude-vcs-ignores \
        `# create an archive` \
        -c \
        `# add the directories to the archive` \
        ./go_proj/  \
        ./go_proj/vendor \
        `# compute the hash of the archive` \
        | md5sum)

    # to test, echo the value that we got and see if it what we wanted
    run echo "$got"
    assert_output --partial "$want"
}

@test "happy path - expected hash of zipfile does not change" {
    # the expected hash came from running:
    #
    #   ./archive.sh reproducible-gzip --best -c ./test/test_data/go_proj/main.go | md5sum
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="df33befa3b10692f45a5860889afa633"

    got=$(./archive.sh reproducible-gzip \
        `# use the best compression at the expense of time to compress` \
        --best \
        `# write the output to stdout` \
        -c \
        `# specify the file to gzip` \
        ./test/test_data/go_proj/main.go \
        `# compute the hash of the gzip file` \
        | md5sum)

    # to test, echo the value that we got and see if it what we wanted
    run echo "$got"
    assert_output --partial "$want"
}

@test "happy path - archiving a go project" {
    # the expected hash came from running:
    #
    #   ./archive.sh go-proj ./test/test_data/go_proj | md5sum
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="3b9d93fc0703a6c81629525cc5e3daba"

    got=$(./archive.sh go-proj \
        `# the directory containing the go project` \
        ./test/test_data/go_proj \
        `# compute the hash of the archive` \
        | md5sum)

    # to test, echo the value that we got and see if it what we wanted
    run echo "$got"
    assert_output --partial "$want"

    # and while we are at it, let's make sure that the test data is up to date.
    # If the test data is out of date, then you will probably need to
    # update it.  See `Makefile` for more information.
    run md5sum ./test/test_data/go-proj-src.tgz
    assert_output --partial "$want"
}

@test "happy path - package a go project" {
    # the expected hash came from running:
    #
    #   ./archive.sh package /tmp/archive-package-assets ./test/test_data/go-proj-src.tgz go-proj "go-proj 1 2 3"
    #   cat /tmp/archive-package-assets/eif-description.json
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="3e7c6fe6c20209276c1d7678b2afe5994044183ecca5bbb23c5635dd0f861415f8787beff5d0239d77b8ad203b33acb2"

    ./archive.sh package $BATS_TEST_TMPDIR/assets3Args ./test/test_data/go-proj-src.tgz go-proj "go-proj 1 2 3"

    # to test, extract the PCR0
    run jq .Measurements.PCR0 $BATS_TEST_TMPDIR/assets3Args/eif-description.json
    assert_output --partial "$want"

    # and we test that the PCR0 value changes if we change the "run string"
    ./archive.sh package $BATS_TEST_TMPDIR/assets5Args ./test/test_data/go-proj-src.tgz go-proj "go-proj 1 2 3 4 5"

    # again extract the PCR0
    run jq .Measurements.PCR0 $BATS_TEST_TMPDIR/assets5Args/eif-description.json
    refute_output --partial "$want"
}

@test "create a docker container for a multi-app project" {
    # in this test, we check that given a go project that builds
    # multiple binaries, we can create a docker container for
    # each binary.  We then run the container and check that the
    # docker container works as expected.

    src=./test/test_data/go_proj

    nix-build ./templates/docker.nix \
        --arg cmd '[ "app1" "1" "2"]' \
        --arg src "$src" \
        --argstr imageName archive-package \
        --argstr tagName latest \
        --out-link $BATS_TEST_TMPDIR/output/result
    docker load < $BATS_TEST_TMPDIR/output/result
    run docker run --rm archive-package:latest
    assert_output "Hello from app 1 with args '[1 2]'"

    nix-build ./templates/docker.nix \
        --arg cmd '[ "app2" "3"]' \
        --arg src "$src" \
        --argstr imageName archive-package \
        --argstr tagName latest \
        --out-link $BATS_TEST_TMPDIR/output/result
    docker load < $BATS_TEST_TMPDIR/output/result
    run docker run --rm archive-package:latest
    assert_output "Hello from app 2 with args '[3]'"
}
