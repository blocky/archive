nix-build-result=result
output-eif=myeif.eif
# todo update latest to a different tag
docker-uri=hello-docker:latest

export SOURCE_DATE_EPOCH=0

run:
	docker build --platform linux/amd64 -t ${docker-uri} .
	docker build -t nitro-cli-image ./nitro-cli/
	docker run --rm \
		-v .:/output \
		-v /var/run/docker.sock:/var/run/docker.sock \
		nitro-cli-image \
	    nitro-cli build-enclave --docker-uri ${docker-uri} --output-file output/${output-eif}
clean:
	rm -f ${output-eif}

