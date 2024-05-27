
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
    rm -rf "$TMP_DIR"
}

@test "fails with no argument" {
   run archive.sh
   assert_failure
}

@test "fails with one argument" {
   run archive.sh something
   assert_failure
}

@test "happy path - expected hash of archive does not change" {
    # the expected hash came from running:
    # ./archive.sh ./test/test_data/go_proj source.tar && md5sum source.tar.gz
    #
    # Yes, it does assume that the code is correct.  However, here we are more
    # concerned with the value changing on systems and not the value itself.
    # So, if we do run this test and it changes, it indicates there is a
    # problem on the system.
    local want="9efc01b2c94118f7901f8df6d78fb2d5"

    local tarFileName="source.tar"

    run archive.sh $DIR/test_data/go_proj/ "$TMP_DIR/$tarFileName"
    assert_success


    run md5sum "$TMP_DIR/$tarFileName.gz"
    assert_output --partial "9efc01b2c94118f7901f8df6d78fb2d5"
}
