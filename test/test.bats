
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

@test "terminates when not in nix shell" {
    # in this test, we set the environment variable to something different
    # than what the nix shell expected
    run bash -c 'IN_NIX_SHELL=nope ./archive.sh help'
    assert_failure
}

@test "warns when not in nix shell but running unsafe" {
    # in this test, we set the environment variable to something different
    # than what the nix shell expected
    run bash -c 'IN_NIX_SHELL=nope ./archive.sh --unsafe help'
    assert_output --partial "WARNING"
}

@test "happy path - expected hash of archive does not change" {
    # the expected hash came from running:
    #
    #   ./archive.sh repro-tar -C ./test/test_data/ --exclude-vcs --exclude-vcs-ignores -c ./go_proj/ ./go_proj/vendor | md5sum
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="cedbc0b9865663812bdcddb8979905d1"

    got=$(./archive.sh repro-tar \
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
    assert_output --partial $want
}

@test "happy path - expected hash of zipfile does not change" {
    # the expected hash came from running:
    #
    #   ./archive.sh repro-gzip --best -c ./test/test_data/go_proj/main.go | md5sum
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="8b4c32449a7bf5008400569662ccc43e"

    got=$(./archive.sh repro-gzip \
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
    assert_output --partial $want
}
