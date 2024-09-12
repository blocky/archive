.PHONY: test

run-go-proj:
	make -C ./test/test_data/go_proj/ run-all

test:
	./test/bats/bin/bats test/test.bats

update-test-data:
	./archive.sh go-proj ./test/test_data/go_proj > ./test/test_data/go-proj-src.tgz
