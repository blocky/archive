
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

@test "happy path - expected hash of archive does not change" {
    # the expected hash came from running:
    #
    #   ./archive.sh repro-tar -C ./test/test_data/ --exclude-vcs --exclude-vcs-ignores -c ./go_proj/ ./go_proj/vendor | md5sum
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="33c31dfa677be99a4a1fac34b69d2075"

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
    local want="df33befa3b10692f45a5860889afa633"

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

@test "happy path - archiving a go project" {
    # the expected hash came from running:
    #
    #   ./archive.sh go-proj ./test/test_data/go_proj | md5sum
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="d41d8cd98f00b204e9800998ecf8427e"

    got=$(./archive.sh go-proj \
        `# the directory containing the go project` \
        ./test/test_data/go_proj |
        `# compute the hash of the archive` \
        | md5sum)

    # to test, echo the value that we got and see if it what we wanted
    run echo "$got"
    assert_output --partial $want
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
    local want="0ede36621dee8727d23cd03a3b2c464f7e4c0d3e7c17f026db7304b94ebec30ec725436ea7fa1ebc163ac41ab05383d2"

    ./archive.sh package $BATS_TEST_TMPDIR/assets ./test/test_data/go-proj-src.tgz go-proj "go-proj 1 2 3"

    # to test, echo the value that we got and see if it what we wanted
    run jq .Measurements.PCR0 $BATS_TEST_TMPDIR/assets/eif-description.json
    assert_output --partial $want
}

