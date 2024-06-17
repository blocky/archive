
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/..:$PATH"

    # setup the temp directory for testing
    # make sure this is cleaned up in the teardown!!
    TMP_DIR=/tmp/archive-test-dir
    mkdir -p "$TMP_DIR"
}

teardown() {
    # clean up the temp directory
    echo rm -rf "$TMP_DIR"
}

@test "happy path - expected hash of archive does not change" {
    # the expected hash came from running:
    #
    #   docker build -q -t archive . && \
    #       docker run -v ./test/test_data/go_proj:/src -v .:/dst archive /src /dst/source.tar.gz && \
    #       md5sum ./source.tar.gz
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing when building on different systems and
    # not the value itself. So, if we do run this test and it changes, it
    # indicates there is a problem with some build tool.
    local want="cedbc0b9865663812bdcddb8979905d1"

    local outFileName="source.tar"

    run ./archive.sh repro-tar \
        -C ./test/test_data/ \
        --exclude-vcs \
        --exclude-vcs-ignores \
        -cf "$TMP_DIR/$outFileName" \
        ./go_proj/  \
        ./go_proj/vendor \
    assert_success

    run md5sum "$TMP_DIR/$outFileName"
    assert_output --partial $want
}
