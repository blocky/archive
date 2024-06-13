nix-build-result=result
output-eif=myeif.eif
docker-image-name=hello-docker
docker-image-tag=latest

run:
	nix-build nix-stuff/docker.nix \
		--arg appDotNix "./nix-stuff/app.nix" \
		--argstr cmd "/bin/go-proj" \
		--argstr dockerImageName ${docker-image-name} \
		--argstr dockerImageTag ${docker-image-tag} \
		--out-link ${nix-build-result}
	docker load < ${nix-build-result}
	docker build -t nitro-cli-image ./nitro-cli/
	docker run --rm \
		-v .:/output \
		-v /var/run/docker.sock:/var/run/docker.sock nitro-cli-image \
	    nitro-cli build-enclave --docker-uri ${docker-image-name}:${docker-image-tag} --output-file output/${output-eif}
	rm ${nix-build-result}
	docker run --rm ${docker-image-name}:${docker-image-tag}
clean:
	rm -f ${nix-build-result} ${output-eif}
